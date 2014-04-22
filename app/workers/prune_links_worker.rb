class PruneLinksWorker < CoreWorker
  include Trackable
  include ConnectionWrapper

  sidekiq_options queue: :slow_db, retry: true

  LOG_RECORD_SCHEMA = {
    links_passed: Integer,
    links_pruned: Integer,
    transition:   String,
    next_jid:     String
  }

  def init(opts)
    opts.symbolize_keys!
    return false unless @domain = opts[:domain]
    return false if ScrapePagesWorker.jobs_in_flight_with_domain(@domain).any?
    @link_store = LinkMessageQueue.new(domain: @domain)
  end

  def perform(opts)
    return unless opts && init(opts)
    track
    @link_store.each_message do |msg|
      if msg.listing_id.nil? && (listing = db { Listing.find_by_url(msg.url) }) && listing.try(:fresh?)
        @link_store.rem(msg.url)
        record_incr(:links_pruned)
      else
        record_incr(:links_passed)
      end
    end
    transition
    stop_tracking
  end

  def transition
    return if @link_store.empty?
    next_jid = ScrapePagesWorker.perform_async(domain: @domain)
    record_set(:transition, "ScrapePagesWorker")
    record_set(:next_jid, next_jid)
  end
end
