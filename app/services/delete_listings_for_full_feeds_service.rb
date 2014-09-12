class DeleteListingsForFullFeedsService < CoreService
  include ConnectionWrapper

  def each_job
    CoreService.mutex.synchronize {
      Site.full_product_feed_sites.each do |site|
        next if Stretched::ObjectQueue.new("#{site.domain}/listings").any?
        db do
          Listing.where(:seller_domain => site.domain).where("updated_at < ?", site.read_at).find_in_batches do |batch|
            yield(klass: "DeleteListingsWorker", arguments: batch.map(&:id))
          end
        end
      end
    }
  end
end
