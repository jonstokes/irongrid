class PopulateSessionQueueWorker < Bellbro::Worker

  sidekiq_options :queue => :crawls, :retry => true

  attr_accessor :site, :timer, :domain
  delegate :timed_out?, to: :timer

  track_with_schema(
    sessions_added:  Integer,
  )

  def init(opts)
    opts.symbolize_keys!
    return false unless opts && @domain = opts[:domain]
    @site = IronCore::Site.new(domain: @domain)
    return false unless PopulateSessionQueueWorker.should_run?(@site) && i_am_alone_with_this_domain?
    @session_queue = @site.session_queue
    return false if @session_queue.any?
    track
    true
  end

  def perform(opts)
    return unless opts && init(opts)
    @session_queue.add(site.sessions)
    record_set :sessions_added, site.sessions.count
    site.mark_read!

    stop_tracking
  end

  def self.should_run?(site)
    site.should_read? &&
      !site.session_queue.is_being_read? &&
      site.product_links_queue.empty? &&
      site.link_message_queue.empty? &&
      !prune_refresh_push_cycle_is_running?(site.domain)
  end

  def self.prune_refresh_push_cycle_is_running?(domain)
    PruneLinksWorker.jobs_in_flight_with_domain(domain).any? ||
      RefreshLinksWorker.jobs_in_flight_with_domain(domain).any? ||
      PushProductLinksWorker.jobs_in_flight_with_domain(domain).any?
  end
end
