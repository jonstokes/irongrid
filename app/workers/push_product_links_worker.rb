class PushProductLinksWorker < Bellbro::Worker

  sidekiq_options :queue => :crawls, :retry => true

  LOG_RECORD_SCHEMA = {
    links_deleted:   Integer,
    sessions_pushed: Integer,
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
    @urls = Set.new
    @session_q = Stretched::SessionQueue.new(site.domain)
    @link_store = LinkMessageQueue.new(domain: site.domain)
    track
    true
  end

  def perform(opts)
    return unless init(opts)
    while !timed_out? && !finished? && msg = @link_store.pop
      record_incr(:links_deleted)
      @urls << msg.url
    end

    record_set :sessions_pushed, @session_q.push(new_session).count
    transition
    stop_tracking
  end

  def transition
    if @link_store.any?
      next_jid = self.class.perform_async(domain: site.domain)
      record_set(:transition, "#{self.class.to_s}")
      record_set(:next_jid, next_jid)
    end
  end

  def finished?
    @urls.size >= 300
  end

  def new_session
    return unless @urls.try(:any?)
    site.product_session_format.merge('urls' => url_list)
  end

  def url_list
    @urls.to_a.map { |url| { url: url } }
  end

end
