class PullProductLinksWorker < Bellbro::Worker
  sidekiq_options :queue => :crawls, :retry => true

  track_with_schema(
    objects_deleted: Integer,
    links_created:   Integer,
    transition:      String,
    next_jid:        String
  )

  attr_accessor :domain, :timer, :site
  delegate :timed_out?, to: :timer

  def init(opts)
    opts.symbolize_keys!
    return false unless opts && @domain = opts[:domain]
    @site = IronCore::Site.new(domain: @domain)
    @timer = RateLimiter.new(opts[:timeout] || 1.hour.to_i)
    @link_store = IronCore::LinkMessageQueue.new(domain: site.domain)
    @object_q = Stretched::ObjectQueue.new("#{site.domain}/product_links")
    track
    true
  end

  def perform(opts)
    return unless init(opts)
    while !timed_out? && obj = @object_q.pop
      record_incr(:objects_deleted)
      next unless obj.object && obj.object.product_link
      record_incr(:links_created)
      @link_store.push IronCore::LinkMessage.new(url: obj.object.product_link)
    end
    stop_tracking
  end
end
