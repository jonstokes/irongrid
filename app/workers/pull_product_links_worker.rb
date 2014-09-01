class PullProductLinksWorker < CoreWorker
  include Trackable

  LOG_RECORD_SCHEMA = {
    objects_deleted: Integer,
    links_created:   Integer,
    transition:      String,
    next_jid:        String
  }

  attr_accessor :domain, :timer, :site
  delegate :timed_out?, to: :timer

  def init(opts)
    opts.symbolize_keys!
    return false unless opts && domain = opts[:domain]
    @site = Site.new(domain: domain)
    @timer = RateLimiter.new(opts[:timeout] || 1.hour.to_i)
    @link_store = LinkMessageQueue.new(domain: site.domain)
    @object_q = Stretched::ObjectQueue.find_or_create("#{site.domain}/product_links")
    track
    true
  end

  def perform(opts)
    return unless init(opts)
    while !timed_out? && obj = @object_q.pop
      record_incr(:objects_deleted)
      record_incr(:links_created) if @link_store.push LinkMessage.new(url: obj.object.product_link)
    end
    stop_tracking
  end
end