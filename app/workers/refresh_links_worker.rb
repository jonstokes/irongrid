class RefreshLinksWorker < BaseWorker
  sidekiq_options queue: :db_slow_high, retry: true

  track_with_schema(
    links_created: Integer,
    transition:    String,
    next_jid:      String
  )

  before :should_run?, :track
  after { log "Refresh links for #{domain} finished." }
  after :transition, :stop_tracking

  def call
    IronBase::Listing.with_each_stale(@domain) do |batch|
      batch.each do |listing|
        msg = convert_to_link_message(listing)
        msg.update(jid: jid)
        record_incr(:links_created) unless site.link_message_queue.add(msg).zero?
        status_update
      end
    end
  end

  def transition
    next_jid = PushProductLinksWorker.perform_async(domain: domain)
    record_set(:transition, "PushProductLinksWorker")
    record_set(:next_jid, next_jid)
  end

  def self.should_run?(site)
    !site.full_feed && # Don't run unless the site actually uses the LMQ
      site.session_queue_inactive? &&
      site.product_links_queue.empty? &&
      PushProductLinksWorker.jobs_in_flight_with_domain(site.domain).empty?
  end

  private

  def convert_to_link_message(listing)
    IronCore::LinkMessage.new(
      url:                listing.url.page,
      current_listing_id: listing.id,
      listing_digest:     listing.digest,
    )
  end
end
