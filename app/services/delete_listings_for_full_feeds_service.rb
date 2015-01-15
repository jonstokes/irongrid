class DeleteListingsForFullFeedsService < CoreService
  include ConnectionWrapper

  def each_job
    CoreService.mutex.synchronize {
      Site.full_product_feed_sites.each do |site|
        next if Stretched::ObjectQueue.new("#{site.domain}/listings").any?
        stale_threshold = site.read_at || 1.days.ago
          query_hash = IronBase::Search::Search.new(
            filters: {
                stale: stale_threshold,
                domain: site.domain
            }
        ).query_hash
        IronBase::Listing.find_each(query_hash) do |batch|
          yield(klass: 'DeleteListingsWorker', arguments: batch.map(&:id))
        end
      end
    }
  end
end
