class PushProductLinksWorker < CoreWorker
  include Trackable

  LOG_RECORD_SCHEMA = {
    objects_deleted: Integer,
    sessions_pushed: Integer,
    transition:      String,
    next_jid:        String
  }

  attr_accessor :domain, :timer, :site
  delegate :timed_out?, to: :timer

  def init(opts)
    return false unless opts && domain = opts[:domain]
    @site = Site.new(domain: domain)
    @timer = RateLimiter.new(opts[:timeout] || 1.hour.to_i)
    @urls = Set.new
    @session_q = Stretched::SessionQueue.find_or_create(site.domain)
    @object_q = Stretched::ObjectQueue.find_or_create("#{site.domain}/product_links")
    track
    true
  end

  def perform(opts)
    return unless init(opts)
    while !timed_out? && !finished? && obj = @object_q.pop
      @urls << obj.object.product_link
    end
    merge_stale_urls

    record_set :objects_deleted, (300 - @urls.size)
    record_set :sessions_pushed, @session_q.push(new_session).count
    transition
    stop_tracking
  end

  def transition
    if @session_q.any?
      next_jid = self.class.perform_async(domain: site.domain)
      record_set(:transition, "#{self.class.to_s}")
    else
      next_jid = PullListingsWorker.perform_in(20.minutes, site.domain)
      record_set(:transition, "PullListingsWorker")
    end
    record_set(:next_jid, next_jid)
  end

  def merge_stale_urls
    Listing.with_each_stale_listing_for_domain(@site.domain) do |listing|
      @urls << listing.bare_url
    end
  end

  def finished?
    @urls.size >= 300
  end

  def new_session
    site.product_session_format.merge('urls' => url_list)
  end

  def url_list
    @urls.to_a.map { |url| { url: url } }
  end

end
