class DeleteListingsForFullFeedsService < BaseService
  track_with_schema(
      jobs_started: Integer,
      listings_deleted: Integer
  )
  poll_interval 3600
  worker_class DeleteListingsWorker

  def start_jobs
    each_job do |job, domain|
      jid = worker_class.perform_async(job)
      log "Starting job #{jid} #{worker_class.name} for #{domain} with #{job.inspect}."
      record_incr(:jobs_started)
      log "Job #{jid} will delete #{record[:data][:listings_deleted]} for #{domain}"
      status_update(true)
      record[:data][:listings_deleted] = 0
    end
  end

  def each_job
    IronCore::Site.each_full_product_feed_site do |site|
      next unless should_add_job?(site)
      IronBase::Listing.find_each(query_hash(site)) do |batch|
        record[:data][:listings_deleted] += batch.size
        yield batch.map(&:id), site.domain
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
