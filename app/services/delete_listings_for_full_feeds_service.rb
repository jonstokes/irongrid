class DeleteListingsForFullFeedsService < CoreService
  include ConnectionWrapper

  def each_job
    CoreService.mutex.synchronize {
      Site.full_product_feed_sites.each do |site|
        next if Stretched::ObjectQueue.new("#{site.domain}/listings").any?
          query_hash = IronBase::Search::Search.new(
            filters: {
                stale: site.read_at,
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
