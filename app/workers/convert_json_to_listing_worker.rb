class ConvertJsonToListingWorker < CoreWorker
  include Trackable

  attr_accessor :domain, :timer
  delegate :timed_out?, to: :timer

  LOG_RECORD_SCHEMA = {
    db_writes:       Integer,
    objects_deleted: Integer,
    pages_read:      Integer,
    images_added:    Integer,
    transition:      String,
    next_jid:        String
  }

  sidekiq_options :queue => :crawls, :retry => true

  def init(opts)
    opts.symbolize_keys!
    return false unless opts && @domain = opts[:domain]
    @timer = Stretched::RateLimiter.new(opts[:timeout] || 1.hour.to_i)
    @object_queue = ObjectQueue.find(domain)
    return false unless @object_queue.any?
    @counter = 100
    track
    true
  end

  def perform(opts)
    return unless opts && init(opts)

    while !timed_out? && json = @object_queue.pop do
      result = ParseJson.perform(json)
      msg = convert_to_link_message(result)
      WriteListingWorker.perform_async(msg.to_h)
      record_incr(:db_writes)
    end

    transition
  end

  def transition
    if @object_queue.any?
      next_jid = self.class.perform_async(domain: domain)
      record_set(:transition, "#{self.class.to_s}")
      record_set(:next_jid, next_jid)
    end
  end

  def convert_to_link_message(result)
    unless result.not_found?
      update_image(scraper) if scraper.is_valid?
      msg.update(
        page_is_valid:        scraper.is_valid?,
        page_not_found:       scraper.not_found?,
        page_attributes:      scraper.listing
      )
    else
      msg.update(page_not_found: true)
    end
    msg
  end

  def finished?
    (counter -= 1).zero?
  end

  def update_image(scraper)
    return unless image_source = scraper.listing["item_data"]["image_source"]
    if CDN.has_image?(image_source)
      scraper.listing["item_data"]["image_download_attempted"] = true
      scraper.listing["item_data"]["image"] = CDN.url_for_image(image_source)
    else
      scraper.listing["item_data"]["image"] = CDN::DEFAULT_IMAGE_URL
      ImageQueue.new(domain: scraper.listing['seller_domain']).push image_source
      record_incr(:images_added)
    end
end
