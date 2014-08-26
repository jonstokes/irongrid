class PushProductLinksWorker < CoreWorker
  include Trackable

  LOG_RECORD_SCHEMA = {
    objects_deleted: Integer,
    session_created: Integer,
    transition:      String,
    next_jid:        String
  }

  attr_accessor :domain, :timer, :site
  delegate :timed_out?, to: :timer

  def init(opts)
    return false unless opts && @domain = opts[:domain]
    @site = Site.new(domain: @domain)
    @timer = Stretched::RateLimiter.new(opts[:timeout] || 1.hour.to_i)
    @urls = Set.new
    @session_q = SessionQueue.new(domain)
    @object_q = ObjectQueue.new(domain)
  end

  def perform
    return false unless init(opts)
    while !timed_out? && !finished? && obj = @object_q.pop
      @urls.push obj.object[:product_link]
    end
    transition
  ensure
    @session_q.push new_session
  end

  def transition
    if @session_q.any?
      next_jid = self.class.perform_async(domain: domain)
      record_set(:transition, "#{self.class.to_s}")
      record_set(:next_jid, next_jid)
    end
  end

  def finished?
    @urls.size >= 300
  end

  def new_session
    site.product_session_format.merge('urls' => @urls)
  end

end
