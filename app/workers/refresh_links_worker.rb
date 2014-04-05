class RefreshLinksWorker < CoreWorker
  include ConnectionWrapper
  include Trackable

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
    @threshold = Time.now.utc - 4.hours
    track(write_interval: 1)
    true
  end

  def perform(opts)
    opts.symbolize_keys!
    return unless init(opts)

    Listing.stale_listings_for_domain(@domain).each do |listing|
      next unless ld = LinkData.create(listing)
      ld.update(jid: jid)
      @link_store.add(listing.url)
      record_incr(:links_created)
    end

    clean_up
    transition
  end

  def clean_up
    stop_tracking
    notify "Refresh links for #{domain} finished."
  end

  def transition
    CreateLinksWorker.perform_async(domain: domain) unless @site.refresh_only?
  end
end
