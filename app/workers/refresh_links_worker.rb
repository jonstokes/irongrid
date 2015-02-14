class RefreshLinksWorker < BaseWorker
  sidekiq_options queue: :db_slow_high, retry: true

  track_with_schema(
    links_created: Integer,
    transition:    String,
    next_jid:      String
  )

  before :testing, :should_run?, :track
  after { ring "Refresh links for #{domain} finished." }
  after :transition, :stop_tracking

  def testing
    ring "Should run? #{should_run?}"
  end

  def call
    ring "Called with site #{site.domain}, LMQ size is #{site.link_message_queue.size}"
    IronBase::Listing.with_each_stale(site.domain) do |batch|
      batch.each do |listing|
        next if site.link_message_queue.has_key?(listing.url.page)
        msg = convert_to_link_message(listing)
        msg.update(jid: jid)
        record_incr(:links_created) unless site.link_message_queue.add(msg).zero?
        status_update
      end
    end
    ring "Finished site #{site.domain}, LMQ size is #{site.link_message_queue.size}"
  end

  def transition
    next_jid = PushProductLinksWorker.perform_async(domain: domain)
    "Transitioned to #{next_jid}"
    record_set(:transition, "PushLinksWorker")
    record_set(:next_jid, next_jid)
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
