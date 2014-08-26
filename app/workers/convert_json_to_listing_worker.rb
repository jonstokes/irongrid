class ConvertJsonToListingWorker < CoreWorker
  include Trackable
  include UpdateImage

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
    @timer = RateLimiter.new(opts[:timeout] || 1.hour.to_i)
    @object_queue = Stretched::ObjectQueue.find_or_create("#{domain}/listings")
    @image_store = ImageQueue.new(domain: domain)
    return false unless @object_queue.any?
    track
    true
  end

  def perform(opts)
    return unless opts && init(opts)

    while !timed_out? && json = @object_queue.pop do
      result = ParseJson.perform(json)
      msg = convert_to_link_message(result)
      WriteListingWorker.perform_async(msg)
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

  def convert_to_link_message(scraper)
    msg = { url: scraper.listing['url'] }
    unless scraper.not_found?
      update_image(scraper) if scraper.is_valid?
      msg.merge(
        page_is_valid:   scraper.is_valid?,
        page_not_found:  scraper.not_found?,
        page_attributes: scraper.listing
      )
    else
      msg.merge(page_not_found: true)
    end
  end
end
