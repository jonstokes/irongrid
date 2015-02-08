class DeleteListingsForFullFeedsService < Bellbro::Service
  track_with_schema jobs_started: Integer
  poll_interval 3600

  def each_job
    Bellbro::Service.mutex.synchronize {
      IronCore::Site.full_product_feed_sites.each do |site|
        next unless site.session_queue.empty? && site.listings_queue.empty? && site.read_at
          query_hash = IronBase::Listing::Search.new(
            filters: {
                stale: site.read_at,
                seller_domain: site.domain
            }
        ).query_hash
        IronBase::Listing.find_each(query_hash) do |batch|
          yield(klass: 'DeleteListingsWorker', arguments: batch.map(&:id))
        end
      end
    }
  end
end
