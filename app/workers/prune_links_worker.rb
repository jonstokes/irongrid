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
    return false unless PruneLinksWorker.should_run?(@domain) && i_am_alone_with_this_domain?
    @link_store = LinkMessageQueue.new(domain: @domain)
  end

  def perform(opts)
    return unless opts && init(opts)
    track
    @link_store.each_message do |msg|
      if (listing = db { Listing.find_by_url(msg.url) }) && listing.try(:fresh?)
        @link_store.rem(msg.url)
        record_incr(:links_pruned)
      else
        record_incr(:links_passed)
      end
      status_update
    end
    transition
    stop_tracking
  end

  def transition
    return if @link_store.empty?
    next_jid = RefreshLinksWorker.perform_async(domain: @domain)
    record_set(:transition, "RefreshLinksWorker")
    record_set(:next_jid, next_jid)
  end

  def self.should_run?(domain)
    LinkMessageQueue.new(domain: domain).any? &&
      !Stretched.session_queue_is_being_read?(domain) &&
      Stretched::ObjectQueue.new("#{domain}/product_links").empty? &&
      RefreshLinksWorker.jobs_in_flight_with_domain(domain).empty? &&
      PushProductLinksWorker.jobs_in_flight_with_domain(domain).empty?
  end
end
