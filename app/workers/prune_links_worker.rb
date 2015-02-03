class PruneLinksWorker < CoreWorker
  include Trackable
  include ConnectionWrapper

  sidekiq_options queue: :db_slow_high, retry: true

  LOG_RECORD_SCHEMA = {
    links_passed: Integer,
    links_pruned: Integer,
    transition:   String,
    next_jid:     String
  }

  def init(opts)
    opts.symbolize_keys!
    return false unless @domain = opts[:domain]
    @site = Site.new(domain: @domain)
    return false unless PruneLinksWorker.should_run?(@site) && i_am_alone_with_this_domain?
    @link_store = @site.link_message_queue
  end

  def perform(opts)
    return unless opts && init(opts)
    track
    @link_store.each_message do |msg|
      if (listing = IronBase::Listing.find_by_url(msg.url).first) && listing.try(:fresh?)
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
    next_jid = RefreshLinksWorker.perform_async(domain: @domain)
    record_set(:transition, "RefreshLinksWorker")
    record_set(:next_jid, next_jid)
  end

  def self.should_run?(site)
    site.session_queue.empty? &&
      !site.session_queue.is_being_read? &&
      site.product_links_queue.empty? &&
      RefreshLinksWorker.jobs_in_flight_with_domain(site.domain).empty? &&
      PushProductLinksWorker.jobs_in_flight_with_domain(site.domain).empty?
  end
end
