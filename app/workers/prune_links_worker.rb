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
    @link_store = LinkQueue.new(domain: @domain)
    @temp_store = @link_store.members
  end

  def perform(opts)
    return unless opts && init(opts)
    track
    while link = @temp_store.shift do
      unless ld = LinkData.find(link)
        troubleshoot(ld)
        next
      end
      if !ld.listing_id && (listing = db { Listing.find_by_url(link) }) && listing.try(:fresh?)
        @link_store.rem(ld.url)
        ld.destroy
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

  def troubleshoot(ld)
    notify "TROUBLESHOOT: Missing linkdata: #{ld.to_h}"
    notify "TROUBLESHOOT: Number of jobs for ScrapePagesWorker in flight with domain #{@domain}: #{ScrapePagesWorker.jobs_in_flight_with_domain(@domain).count}"
  end
end
