class RefreshLinksWorker < CoreWorker
  include ConnectionWrapper
  include Trackable

  sidekiq_options queue: :db_slow_high, retry: true

  LOG_RECORD_SCHEMA = {
    links_created: Integer,
    transition:    String,
    next_jid:      String
  }

  attr_reader :domain, :site
  attr_accessor :scraper

  def init(opts)
    opts.symbolize_keys!
    return false unless opts && (@domain = opts[:domain])
    @site = Site.new(domain: domain, source: :redis)
    @link_store = LinkMessageQueue.new(domain: domain)
    true
  end

  def perform(opts)
    return unless opts && init(opts)
    track
    Listing.with_each_stale_listing_for_domain(@domain) do |listing|
      next if @link_store.has_key?(listing.bare_url)
      msg = LinkMessage.new(listing)
      msg.update(jid: jid)
      record_incr(:links_created) unless @link_store.add(msg).zero?
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
    next_jid = PushProductLinksWorker.perform_async(domain: domain)
    record_set(:transition, "PushLinksWorker")
    record_set(:next_jid, next_jid)
  end
end
