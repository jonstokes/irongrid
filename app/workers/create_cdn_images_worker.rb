class CreateCdnImagesWorker < BaseWorker
  include Sunbro

  sidekiq_options queue: :crawl_images, retry: false

  track_with_schema(
    images_created: Integer,
    transition:     String,
    next_jid:       String
  )

  before :should_run?, :track
  after :transition, :stop_tracking
  always :close_http_connections

  def call
    while !timer.timed_out? && (image_source = site.image_queue.pop) do
      rate_limiter.with_limit do
        CDN::Image.create(source: image_source, http: http)
      end
      record_incr(:images_created)
      status_update
    end
  end

  def self.should_run?(site)
    super && site.image_queue.any?
  end

  def transition
    return unless should_run?
    next_jid = CreateCdnImagesWorker.perform_async(domain: domain)
    record_set(:transition, "CreateCdnImagesWorker")
    record_set(:next_jid, next_jid)
  end
end
