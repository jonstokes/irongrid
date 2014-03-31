class CreateCdnImagesWorker < CoreWorker

  sidekiq_options :queue => :crawls, :retry => false

  LOG_RECORD_SCHEMA = {
    images_created: Integer,
    transition:     String
  }

  attr_reader :domain

  def init(opts)
    return false unless opts && @domain = opts[:domain]
    @image_store = ImageQueue.new(domain: domain)
    return false if @image_store.empty?
    @site = Site.new(domain: domain)
    @rate_limiter = RateLimiter.new(@site.rate_limit)
    @timeout ||= ((60.0 / @site.rate_limit.to_f) * 60).to_i
    true
  end

  def perform(opts)
    return unless init(opts)
    track
    while (image_source = @image_store.pop) && !timed_out? do
      @rate_limiter.with_limit { CDN.upload_image(image_source) }
      record_incr(:images_created)
      status_update
    end
    transition
    stop_tracking
  end

  def transition
    if @image_store.any?
      CreateCdnImagesWorker.perform(domain: domain)
      record_set(:transition, "CreateCdnImagesWorker")
    end
  end

  def timed_out?
    (@timeout -= 1).zero?
  end
end
