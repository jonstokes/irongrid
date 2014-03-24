class RefreshLinksWorker < CoreWorker
  include PageUtils

  sidekiq_options :queue => :db_read, :retry => false

  attr_reader :domain, :site, :query_conditions, :record, :deleted_listing_count, :updated_listing_count
  attr_accessor :scraper

  def init(opts)
    return unless opts
    opts.symbolize_keys!
    return false unless (@domain = opts[:domain])
    @site = Site.new(domain: domain, source: :redis)
    record_opts = {
      append_record:    true,
      listings_deleted: 0,
      listings_updated: 0,
      listings_read:    0,
      write_interval:   5
    }
    track(record_opts)
    @link_store = LinkQueue.new(domain: domain)
    @query_conditions = {
      site_id: site.id,
      type:    ["RetailListing", "ClassifiedListing"],
    }
    @threshold = Time.now - 4.hours

    return false unless listings.count > 0

    notify "Found #{listings.count} listings for #{domain}."
    true
  end

  def perform(opts)
    return unless init(opts)
    return unless listings.any?

    listings.each do |listing|
      next unless ld = LinkData.create(listing)
      ld.update(jid: jid)
      @link_store.add(listing.url)
    end

    clean_up
    transition
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

  def transition
    CreateLinksWorker.perform_async(domain: domain)
  end
end
