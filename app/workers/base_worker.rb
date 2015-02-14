class BaseWorker < Bellbro::Worker
  def site
    @site ||= IronCore::Site.find(domain) rescue nil
  end

  def timer
    @timer ||= RateLimiter.new(context[:timeout] || 1.hour.to_i)
  end

  def rate_limiter
    @rate_limiter ||= RateLimiter.new(site.rate_limit)
  end

  def timed_out?
    timer.timed_out?
  end

  def domain
    @domain ||= context[:domain]
  end

  def i_am_alone_with_this_domain?
    ring "Checking aloneness for #{domain}: jobs => #{self.class.jobs_with_domain(domain).inspect}, workers => #{self.class.workers_with_domain(domain)}"
    self.class.jobs_with_domain(domain).select { |j| jid != j[:jid] }.empty? &&
        self.class.workers_with_domain(domain).select { |j| jid != j[:jid] }.empty?
  end

  def should_run?
    (self.class.should_run?(site) && i_am_alone_with_this_domain?) || abort!
  end

  def self.should_run?(site)
    !!site
  end

  def self.prune_refresh_push_cycle_is_running?(domain)
    PruneLinksWorker.jobs_in_flight_with_domain(domain).any? ||
        RefreshLinksWorker.jobs_in_flight_with_domain(domain).any? ||
        PushProductLinksWorker.jobs_in_flight_with_domain(domain).any?
  end

end