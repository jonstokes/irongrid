class PushProductLinksWorker < CoreWorker
  include Trackable

  LOG_RECORD_SCHEMA = {
    objects_deleted: Integer,
    urls_added:      Integer,
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
    @object_q = ObjectQueue.new("#{domain}/product_link")
    true
  end

  def perform
    return unless init(opts)
    while !timed_out? && !finished? && obj = @object_q.pop
      @urls.push obj.object[:product_link]
    end
    record_set :objects_deleted, (300 - @urls.size)
    transition
  ensure
    record_set :urls_added, @session_q.push(new_session)
  end

  def transition
    if @session_q.any?
      next_jid = self.class.perform_async(domain: domain)
      record_set(:transition, "#{self.class.to_s}")
    else
      next_jid = ConvertJsonToListingWorker.perform_in(20.minutes, domain)
      record_set(:transition, "ConvertJsonToListingWorker")
    end
    record_set(:next_jid, next_jid)
  end

  def finished?
    @urls.size >= 300
  end

  def new_session
    site.product_session_format.merge('urls' => @urls)
  end

end
