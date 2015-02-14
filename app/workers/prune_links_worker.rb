class PruneLinksWorker < BaseWorker

  sidekiq_options queue: :db_slow_high, retry: true

  track_with_schema(
    links_passed: Integer,
    links_pruned: Integer,
    transition:   String,
    next_jid:     String
  )

  before :testing, :should_run?, :track
  after :transition, :stop_tracking

  def testing
    ring "Should run? #{should_run?}: #{!!site.product_link_adapter}, #{site.session_queue_inactive?}, #{site.product_links_queue.empty?}, #{!self.class.prune_refresh_push_cycle_is_running?(site.domain)}"
  end

  def call
    ring "Called with site #{site.domain}, LMQ size is #{site.link_message_queue.size}"
    links_to_prune = []
    site.link_message_queue.each_message do |msg|
      if (listing = IronBase::Listing.find_by_url(msg.url).first) && listing.try(:fresh?)
        links_to_prune << msg.url
        record_incr(:links_pruned)
      else
        record_incr(:links_passed)
      end
      status_update
    end
    site.link_message_queue.rem(links_to_prune)
    ring "# Finished site #{site.domain}. Final LMQ size is #{site.link_message_queue.size}. Pruned #{links_to_prune.size} links."
  end

  def transition
    next_jid = RefreshLinksWorker.perform_async(domain: @domain)
    ring "Transitioned to #{next_jid}"
    record_set(:transition, "RefreshLinksWorker")
    record_set(:next_jid, next_jid)
  end

  def self.should_run?(site)
    site.product_link_adapter && # Don't run unless the site actually uses the LMQ
      site.session_queue_inactive? &&
      site.product_links_queue.empty? &&
      !prune_refresh_push_cycle_is_running?(site.domain)
  end
end