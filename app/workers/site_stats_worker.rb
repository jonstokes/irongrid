class SiteStatsWorker < BaseWorker

  sidekiq_options queue: :db_slow_low

  track_with_schema(
    active_listings: Integer,
    inactive_listings: Integer,
    stale_listings: Integer,
    stalest_listing: Time
  )

  before :track
  after :stop_tracking

  def call
    get_active_listings
    get_inactive_listings
    get_stale_listings
    get_stalest_listing
  end

  def self.should_run?(domain)
    self.jobs_in_flight_with_domain(domain).empty?
  end

  private

  def get_active_listings
    active_listings = IronBase::Listing.active_count_for_domain(domain)
    site.update_stats(active_listings: active_listings)
    record_set(:active_listings, active_listings)
  end

  def get_inactive_listings
    inactive_listings = IronBase::Listing.inactive_count_for_domain(domain)
    site.update_stats(inactive_listings: inactive_listings)
    record_set(:inactive_listings, inactive_listings)
  end

  def get_stale_listings
    stale_listings = IronBase::Listing.stale_count_for_domain(domain)
    site.update_stats(stale_listings: stale_listings)
    record_set(:stale_listings, stale_listings)
  end

  def get_stalest_listing
    if stalest_listing = IronBase::Listing.stalest_for_domain(domain)
      time = stalest_listing.updated_at.to_time
      site.update_stats(stalest_listing: time)
      record_set(:stalest_listing, time)
    else
      site.update_stats(stalest_listing: nil)
    end
  end
end

