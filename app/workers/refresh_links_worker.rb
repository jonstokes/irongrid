class RefreshLinksWorker < CoreWorker
  include ConnectionWrapper
  include Trackable

  LOG_RECORD_SCHEMA = {
    links_created: Integer,
    transition:    String,
    next_jid:      String
  }

  sidekiq_options queue: :slow_db, retry: true

  attr_reader :domain, :site
  attr_accessor :scraper

  def init(opts)
    opts.symbolize_keys!
    return false unless opts && (@domain = opts[:domain])
    return false if ScrapePagesWorker.jobs_in_flight_with_domain(@domain).any?
    @site = Site.new(domain: domain, source: :redis)
    @link_store = LinkQueue.new(domain: domain)
    true
  end

  def perform(opts)
    return unless opts && init(opts)
    track
    Listing.with_each_stale_listing_for_domain(@domain) do |listing|
      next unless @link_store.add(listing.url)
      ld = LinkData.create(listing)
      ld.update(jid: jid)
      record_incr(:links_created)
      status_update
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
    next_jid = CreateLinksWorker.perform_async(domain: domain)
    record_set(:transition, "CreateLinksworker")
    record_set(:next_jid, next_jid)
  end
end
