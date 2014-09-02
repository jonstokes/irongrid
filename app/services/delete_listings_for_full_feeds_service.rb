class DeleteListingsForFullFeedsService < CoreService
  include ConnectionWrapper

  def start_jobs
    CoreService.mutex.synchronize {
      return if DeleteListingsForFullFeedsService.queued_jobs.any?
      Site.full_product_feed_sites.each do |site|
        db do
          Listing.where(:seller_domain => site.domain).where("updated_at < ?", site.read_at).find_in_batches do |batch|
            DeleteListingsWorker.perform_async(batch.map(&:id))
            record_incr(:jobs_started) unless Rails.env.test?
          end
        end
      end
    }
  end
end
