class CreateCdnImagesWorker < CoreWorker
  include Trackable

  sidekiq_options :queue => :crawl_images, :retry => false

  LOG_RECORD_SCHEMA = {
    images_created: Integer,
    transition:     String,
    next_jid:       String
  }

  attr_reader :domain, :timer

  def init(opts)
    opts.symbolize_keys!
    return false unless opts && @domain = opts[:domain]
    @image_store = ImageQueue.new(domain: domain)
    @site = Site.new(domain: domain)
    @rate_limiter = RateLimiter.new(@site.rate_limit)
    @timer = RateLimiter.new(opts[:timeout] || 1.hour.to_i)
    @http = PageUtils::HTTP.new
    true
  end

  def perform(opts)
    return unless opts && init(opts)
    track
    while (image_source = @image_store.pop) && !timer.timed_out? do
      @rate_limiter.with_limit do
        CDN::Image.create(source: image_source, http: @http)
      end
      record_incr(:images_created)
      status_update
    end
    transition
    stop_tracking
  ensure
    @http.close
  end

  def transition
    return if @image_store.empty?
    next_jid = CreateCdnImagesWorker.perform_async(domain: domain)
    record_set(:transition, "CreateCdnImagesWorker")
    record_set(:next_jid, next_jid)
  end
end
