class PruneLinksWorker < CoreWorker
  include Trackable
  include ConnectionWrapper

  sidekiq_options queue: :fast_db, retry: true

  LOG_RECORD_SCHEMA = {
    links_checked: Integer,
    links_pruned: Integer,
    transition: String
  }

  def init(opts)
    return false unless @domain = opts[:domain]
    @link_store = LinkQueue.new(domain: @domain)
    @temp_store = Set.new
  end

  def perform(opts)
    opts.symbolize_keys!
    return unless init(opts)
    track
    while link = @link_store.pop do
      ld = LinkData.find(link)
      if !ld.listing_id && (listing = db { Listing.find_by_url(link) }) && listing.try(:fresh?)
        ld.destroy
        record_incr(:links_pruned)
      else
        @temp_store << link
        record_incr(:links_checked)
      end
    end
    @temp_store.each { |link| @link_store.push link }
    transition
    stop_tracking
  end

  def transition
    if @link_store.any?
      ScrapePagesWorker.perform_async(domain: @domain)
      record_set(:transition, "ScrapePagesWorker")
    end
  end
end
