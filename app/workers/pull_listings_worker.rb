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
      next unless scraper = parse(json)
      record_incr(:db_writes)
      update_image(scraper)
    end

    transition
    stop_tracking
  end

  def parse(json)
    if json.error?
      notify "# STRETCHED ERROR on page #{json.page.url}\n#{json.error}"; nil
    else
      scraper = ParseJson.call(
          site:         site,
          listing_json: json.object,
          page:         json.page
      )
      scraper.success? ? scraper: nil
    end
  end

  def transition
    if @object_queue.any?
      next_jid = self.class.perform_async(domain: site.domain)
      record_set(:transition, "#{self.class.to_s}")
      record_set(:next_jid, next_jid)
    end
  end

end
