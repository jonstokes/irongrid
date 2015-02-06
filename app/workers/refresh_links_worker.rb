class RefreshLinksWorker < Bellbro::Worker
  sidekiq_options queue: :db_slow_high, retry: true

  track_with_schema(
    links_created: Integer,
    transition:    String,
    next_jid:      String
  )

  attr_reader :domain, :site
  attr_accessor :scraper

  def init(opts)
    opts.symbolize_keys!
    return false unless opts && (@domain = opts[:domain])
    @site = IronCore::Site.new(domain: domain, source: :redis)
    @link_store = @site.link_message_queue
    true
  end

  def perform(opts)
    return unless opts && init(opts)
    track
    IronBase::Listing.with_each_stale(@domain) do |batch|
      batch.each do |listing|
        next if @link_store.has_key?(listing.url.page)
        msg = IronCore::LinkMessage.new(listing)
        msg.update(jid: jid)
        record_incr(:links_created) unless @link_store.add(msg).zero?
        status_update
      end
    end
    clean_up
    transition
    stop_tracking
  end

  def clean_up
    ring "Refresh links for #{domain} finished."
  end

  def transition
    next_jid = PushProductLinksWorker.perform_async(domain: domain)
    record_set(:transition, "PushLinksWorker")
    record_set(:next_jid, next_jid)
  end
end
