class RefreshLinksWorker < CoreWorker
  include ConnectionWrapper
  include Trackable

  LOG_RECORD_SCHEMA = {
    links_created: Integer,
    transition: String
  }

  sidekiq_options queue: :fast_db, retry: true

  attr_reader :domain, :site
  attr_accessor :scraper

  def init(opts)
    opts.symbolize_keys!
    return false unless opts && (@domain = opts[:domain])
    @site = Site.new(domain: domain, source: :redis)
    @link_store = LinkQueue.new(domain: domain)
    @threshold = Time.now.utc - 4.hours
    true
  end

  def perform(opts)
    return unless opts && init(opts)
    track(write_interval: 1)
    Listing.stale_listings_for_domain(@domain).each do |listing|
      next unless ld = LinkData.create(listing)
      ld.update(jid: jid)
      @link_store.add(listing.url)
      record_incr(:links_created)
    end
    clean_up
    transition
    stop_tracking
  end

  def clean_up
    notify "Refresh links for #{domain} finished."
  end

  def transition
    return if @site.refresh_only?
    CreateLinksWorker.perform_async(domain: domain)
    record_set(:transition, "CreateLinksworker")
  end
end
