class SiteStatsWorker < CoreWorker

  sidekiq_options queue: :slow_db

  attr_reader :domain

  def init(opts)
    opts.symbolize_keys!
    return false unless opts && @domain = opts[:domain]
    true
  end

  def perform(opts)
    return unless opts && init(opts)

    active_listings = Listing.active_count_for_domain(domain)
    notify "Found #{active_listings} active listings for #{domain}"
    inactive_listings = Listing.inactive_count_for_domain(domain)
    notify "Found #{inactive_listings} inactive listings for #{domain}"
    stale_listings = Listing.stale_count_for_domain(domain)
    notify "Found #{stale_listings} stale listings for #{domain}"
    stalest_listing = Listing.stalest_for_domain(domain).try(:id)
    notify "Stalest listing for #{domain} is #{stalest_listing}"

    stats = {
      active_listings: active_listings,
      inactive_listings: inactive_listings,
      stale_listings: stale_listings,
      stalest_listing: stalest_listing,
      updated_at: Time.now.utc
    }

    Site.new(domain: domain, source: :redis).update_stats(stats)
  end
end

