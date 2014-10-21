class PullListingsWorker < CoreWorker
  include Trackable

  sidekiq_options :queue => :crawls, :retry => true

  LOG_RECORD_SCHEMA = {
    db_writes:       Integer,
    objects_deleted: Integer,
    images_added:    Integer,
    transition:      String,
    next_jid:        String
  }

  attr_accessor :domain, :timer, :site
  delegate :timed_out?, to: :timer

  def init(opts)
    opts.symbolize_keys!
    return false unless opts && @domain = opts[:domain]
    @site = Site.new(domain: @domain)
    @timer = RateLimiter.new(opts[:timeout] || 1.hour.to_i)
    @object_queue = Stretched::ObjectQueue.new("#{site.domain}/listings")
    @image_store = ImageQueue.new(domain: site.domain)
    return false unless @object_queue.any?
    track
    true
  end

  def perform(opts)
    return unless opts && init(opts)

    while !timed_out? && json = @object_queue.pop do
      record_incr(:objects_deleted)
      if json.error?
        notify "# STRETCHED ERROR on page #{json.page.url}\n#{json.error}"
        next
      end
      json.site = site
      scraper = ParseJson.perform(json)
      update_image(scraper) if scraper.is_valid?
      scraper_status = scraper.success? ? :success : scraper.status
      WriteListingWorker.perform_async(
        listing: scraper.listing.try(:to_hash),
        page:    scraper.page.to_hash,
        status:  scraper_status
      )
      record_incr(:db_writes)
    end

    transition
    stop_tracking
  end

  def transition
    if @object_queue.any?
      next_jid = self.class.perform_async(domain: site.domain)
      record_set(:transition, "#{self.class.to_s}")
      record_set(:next_jid, next_jid)
    end
  end

  def update_image(scraper)
    return unless image_source = scraper.listing["item_data"]["image_source"]
    if CDN.has_image?(image_source)
      scraper.listing["item_data"]["image_download_attempted"] = true
      scraper.listing["item_data"]["image"] = CDN.url_for_image(image_source)
    else
      scraper.listing["item_data"]["image"] = CDN::DEFAULT_IMAGE_URL
      @image_store.push image_source
      record_incr(:images_added)
    end
  end

end
