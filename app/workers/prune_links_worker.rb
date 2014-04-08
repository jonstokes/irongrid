class PruneLinksWorker < CoreWorker
  include Trackable
  include ConnectionWrapper

  sidekiq_options queue: :fast_db, retry: true

  LOG_RECORD_SCHEMA = {
    links_passed: Integer,
    links_pruned: Integer,
    transition: String
  }

  def init(opts)
    opts.symbolize_keys!
    return false unless @domain = opts[:domain]
    @link_store = LinkQueue.new(domain: @domain)
    @temp_store = @link_store.members
    @pruned_links = []
  end

  def perform(opts)
    return unless opts && init(opts)
    track
    while link = @temp_store.shift do
      ld = LinkData.find(link)
      if !ld.listing_id && (listing = db { Listing.find_by_url(link) }) && listing.try(:fresh?)
        @pruned_links << ld
        record_incr(:links_pruned)
      else
        record_incr(:links_passed)
      end
    end

    @pruned_links.each do |ld|
      ld.destroy
      @link_store.rem(ld.url)
    end

    transition
    stop_tracking
  end

  def transition
    return if @link_store.empty?
    ScrapePagesWorker.perform_async(domain: @domain)
    record_set(:transition, "ScrapePagesWorker")
  end
end
