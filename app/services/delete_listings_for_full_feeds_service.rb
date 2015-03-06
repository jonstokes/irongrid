class DeleteListingsForFullFeedsService < BaseService
  track_with_schema jobs_started: Integer
  poll_interval 3600
  worker_class DeleteListingsWorker

  def each_job
    IronCore::Site.each_full_product_feed_site do |site|
      next unless should_add_job?(site)
      IronBase::Listing.find_each(query_hash(site)) do |batch|
        yield(batch.map(&:id))
      end
    end
  end

  def should_add_job?(site)
    PullListingsWorker.jobs_in_flight_with_domain(site.domain).empty? &&
      site.session_queue.empty? && site.listings_queue.empty? && site.read_at
  end

  private

  def query_hash(site)
    IronBase::Listing::Search.new(
        filters: {
            stale: threshold(site),
            seller_domain: site.domain
        }
    ).query_hash
  end

  def threshold(site)
    return site.read_at - 4.hours unless site.read_interval
    site.read_at - site.read_interval
  end
end
