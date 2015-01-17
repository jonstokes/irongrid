class SiteStatsWorker < CoreWorker
  include Trackable

  sidekiq_options queue: :db_slow_low

  LOG_RECORD_SCHEMA = {
    active_listings: Integer,
    inactive_listings: Integer,
    stale_listings: Integer,
    stalest_listing: Time
  }

  attr_reader :domain

  def init(opts)
    opts.symbolize_keys!
    return false unless opts && @domain = opts[:domain]
    @site = Site.new(domain: domain, source: :redis)
    true
  end

  def perform(opts)
    return unless opts && init(opts)
    track

    active_listings = IronBase::Listing.active_count_for_domain(domain)
    @site.update_stats(active_listings: active_listings)
    record_set(:active_listings, active_listings)

    inactive_listings = IronBase::Listing.inactive_count_for_domain(domain)
    @site.update_stats(inactive_listings: inactive_listings)
    record_set(:inactive_listings, inactive_listings)

    stale_listings = IronBase::Listing.stale_count_for_domain(domain)
    @site.update_stats(stale_listings: stale_listings)
    record_set(:stale_listings, stale_listings)

    if stalest_listing = IronBase::Listing.stalest_for_domain(domain)
      time = stalest_listing.updated_at.to_time
      @site.update_stats(stalest_listing: time)
      record_set(:stalest_listing, time)
    end

    stop_tracking
  end

  def self.should_run?(domain)
    self.jobs_in_flight_with_domain(domain).empty?
  end

end

