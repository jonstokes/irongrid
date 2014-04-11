class SiteStatsWorker < CoreWorker
  include Trackable

  LOG_RECORD_SCHEMA = {
    active_listings: Integer,
    inactive_listings: Integer,
    stale_listings: Integer,
    stalest_listing: Integer
  }

  sidekiq_options queue: :slow_db

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

    active_listings = Listing.active_count_for_domain(domain)
    @site.update_stats(active_listings: active_listings)
    record_set(:active_listings, active_listings)

    inactive_listings = Listing.inactive_count_for_domain(domain)
    @site.update_stats(inactive_listings: inactive_listings)
    record_set(:inactive_listings, inactive_listings)

    stale_listings = Listing.stale_count_for_domain(domain)
    @site.update_stats(stale_listings: stale_listings)
    record_set(:stale_listings, stale_listings)

    stalest_listing = Listing.stalest_for_domain(domain).try(:id)
    @site.update_stats(stalest_listing: stalest_listing)
    record_set(:stalest_listing, stalest_listing) if stalest_listing

    stop_tracking
  end
end

