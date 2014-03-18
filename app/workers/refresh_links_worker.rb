class RefreshLinksWorker < CoreWorker
  include Sidekiq::Worker
  include PageUtils

  sidekiq_options :queue => :scheduled, :retry => false

  attr_reader :domain, :query_conditions, :record, :deleted_listing_count, :updated_listing_count
  attr_accessor :scraper

  def init(opts)
    opts.symbolize_keys!
    return false unless (@domain = opts[:domain]) && i_am_alone?(@domain)
    record_opts = {
      append_record:    true,
      listings_deleted: 0,
      listings_updated: 0,
      listings_read:    0,
      write_interval:   5
    }
    track(record_opts)
    @link_store = LinkSet.new(domain: domain)
    @query_conditions = {
      seller_domain: domain,
      type:          ["RetailListing", "ClassifiedListing"],
    }
    @threshold = Time.now - 4.hours

    return false unless listings.count > 0

    notify "Found #{listings.count} listings for #{domain}."
    true
  end

  def perform(opts)
    return unless opts && init(opts)
    return unless listings.any?

    @link_store.add(listings.map(&:url))

    clean_up
  end

  def listings
    @listings ||= db do
      Listing.where(query_conditions).where(query_conditions).where("updated_at < ?", @threshold).order("updated_at ASC").limit(400)
    end
  end

  def clean_up
    stop_tracking
    notify "Batch iteration finished."
  end
end
