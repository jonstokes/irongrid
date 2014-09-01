class PullListingsWorker < CoreWorker
  include Trackable
  include UpdateImage

  attr_accessor :site, :timer
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
    return false unless opts && domain = opts[:domain]
    @site = Site.new(domain: domain)
    @timer = RateLimiter.new(opts[:timeout] || 1.hour.to_i)
    @object_queue = Stretched::ObjectQueue.find_or_create("#{site.domain}/listings")
    @image_store = ImageQueue.new(domain: site.domain)
    return false unless @object_queue.any?
    track
    true
  end

  def perform(opts)
    return unless opts && init(opts)

    while !timed_out? && json = @object_queue.pop do
      json.site = site
      scraper = ParseJson.perform(json)
      update_image(scraper) if scraper.is_valid?
      msg = LinkMessage.new(scraper)
      WriteListingWorker.perform_async(msg.to_h)
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

end