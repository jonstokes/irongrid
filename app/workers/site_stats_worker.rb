class SiteStatsWorker < CoreWorker

  sidekiq_options queue: :fast_db

  attr_reader :domain

  def init(opts)
    opts.symbolize_keys!
    return false unless opts && @domain = opts[:domain]
    true
  end

  def perform(opts)
    return unless opts && init(opts)

    stats = {
      active_listings: Listing.active_count_for_domain(domain),
      inactive_listings: Listing.inactive_count_for_domain(domain),
      stalest_listing: Listing.stalest_for_domain(domain).id,
      updated_at: Time.now.utc
    }

    Site.new(domain: domain).update(stats: stats)
  end
end

