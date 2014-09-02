class PopulateSessionQueueWorker < CoreWorker
  include Trackable

  attr_accessor :site, :timer
  delegate :timed_out?, to: :timer

  LOG_RECORD_SCHEMA = {
    sessions_added:  Integer,
  }

  sidekiq_options :queue => :slow_db, :retry => true

  def init(opts)
    opts.symbolize_keys!
    return false unless opts && domain = opts[:domain]
    return false unless PopulateSessionQueueWorker.should_run?(domain) && i_am_alone_with_this_domain?
    @site = Site.new(domain: domain)
    @session_queue = Stretched::SessionQueue.find_or_create(domain)
    return false if @session_queue.any?
    track
    true
  end

  def perform(opts)
    return unless opts && init(opts)
    record_set :sessions_added, @session_queue.add(site.sessions).count
    site.mark_read!

    stop_tracking
  end

  def self.should_run?(domain)
    !Stretched.session_queue_is_being_read?(domain) &&
      Stretched::ObjectQueue.new("#{domain}/product_links").empty? &&
      LinkMessageQueue.new(domain: domain).empty? &&
      !prune_refresh_push_cycle_is_running?(domain)
  end

  def self.prune_refresh_push_cycle_is_running?(domain)
    PruneLinksWorker.jobs_in_flight_with_domain(domain).any? ||
      RefreshLinksWorker.jobs_in_flight_with_domain(domain).any? ||
      PushProductLinksWorker.jobs_in_flight_with_domain(domain).any?
  end
end
