class DeleteListingsForFullFeedsService < CoreService
  include ConnectionWrapper

  def start_jobs
    CoreService.mutex.synchronize {
      Site.full_product_feed_sites.each do |site|
        next if Stretched::ObjectQueue.new("#{site.domain}/listings").any?
        db do
          Listing.where(:seller_domain => site.domain).where("updated_at < ?", site.read_at).find_in_batches do |batch|
            removed = batch.map do |listing|
              "#{listing.id}=>#{listing.updated_at}"
            end
            DeleteListingsWorker.perform_async(batch.map(&:id))
            record_incr(:jobs_started) unless Rails.env.test?
          end
        end
      end
    }
  end
end
