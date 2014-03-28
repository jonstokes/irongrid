class DeleteEndedAuctionsService < CoreService
  include ConnectionWrapper

  def start_jobs
    listing_ids = []
    begin
      db do
        Listing.ended_auctions.find_in_batches do |batch|
          puts "Batch size is #{batch.size}"
          puts "Batch ids are #{batch.map(&:id)}"
          DeleteEndedAuctionsWorker.perform_async(batch.map(&:id))
          record_incr(:jobs_started) unless Rails.env.test?
        end
      end
    end until listing_ids.empty?
  end
end
