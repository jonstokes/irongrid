class PullProductLinksWorker < CoreWorker

  sidekiq_options :queue => :crawls, :retry => true

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
    return false unless opts && @domain = opts[:domain]
    @site = Site.new(domain: @domain)
    @timer = RateLimiter.new(opts[:timeout] || 1.hour.to_i)
    @link_store = LinkMessageQueue.new(domain: site.domain)
    @object_q = Stretched::ObjectQueue.new("#{site.domain}/product_links")
    true
  end

  def perform(opts)
    return unless init(opts)
    while !timed_out? && obj = @object_q.pop
      next unless obj.object && obj.object.product_link
      @link_store.push LinkMessage.new(url: obj.object.product_link)
    end
  end
end
