class DeleteListingsForFullFeedsService < Bellbro::Service
  track_with_schema jobs_started: Integer
  poll_interval 3600

  def each_job
    IronCore::Site.full_product_feed_sites.each do |site|
      next unless should_add_job?(site)
      delete_listings_for_site(site)
    end
  end

  def should_add_job?(site)
    DeleteListingsWorker.jobs_in_flight_with_domain(site.domain).empty? &&
    site.session_queue.empty? && site.listings_queue.empty? && site.read_at
  end

  def delete_listings_for_site(site)
    IronBase::Listing.find_each(query_hash(site)) do |batch|
      yield(klass: 'DeleteListingsWorker', arguments: batch.map(&:id))
    end
  end

  def query_hash(site)
    IronBase::Listing::Search.new(
        filters: {
            stale: site.read_at,
            seller_domain: site.domain
        }
    ).query_hash
  end
end
