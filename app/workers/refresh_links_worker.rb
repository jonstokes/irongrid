class RefreshLinksWorker < CoreWorker
  include ConnectionWrapper

  LOG_RECORD_SCHEMA = {
    links_created: Integer,
  }

  sidekiq_options queue: :fast_db, retry: true

  attr_reader :domain, :site
  attr_accessor :scraper

  def init(opts)
    return false unless opts && (@domain = opts[:domain])
    @site = Site.new(domain: domain, source: :redis)
    @link_store = LinkQueue.new(domain: domain)
    @threshold = Time.now - 4.hours
    track(write_interval: 1)
    notify "Found #{listings.count} stale listings for #{domain}."
    true
  end

  def perform(opts)
    opts.symbolize_keys!
    return unless init(opts)

    listings.each do |listing|
      next unless ld = LinkData.create(listing)
      ld.update(jid: jid)
      @link_store.add(listing.url)
      record_incr(:links_created)
    end

    clean_up
    transition
  end

  def listings
    @listings ||= db do
      Listing.where(query_conditions).where("updated_at < ?", @threshold).order("updated_at ASC").limit(400)
    end
  end

  def query_conditions
    "item_data->>'seller_domain' = '#{domain}'"
  end

  def clean_up
    stop_tracking
    notify "Refresh links for #{domain} finished."
  end

  def transition
    CreateLinksWorker.perform_async(domain: domain)
  end
end
