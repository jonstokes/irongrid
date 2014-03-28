class DeleteEndedAuctionsService < CoreService
  include ConnectionWrapper

  def run
    notify "Starting #{self.class} service."
    track
    begin
      generate_jobs
      status_update
      sleep SLEEP_INTERVAL
    end until @done
    stop_tracking
  end

  def generate_jobs
    listing_ids = []
    begin
      listing_ids = db { Listing.ended_auctions.limit(400).map(&:id) }
      puts "Worker found #{Listing.ended_auctions.count} ended auctions"
      notify "Generating #{listing_ids.size} jobs for ended auctions..."
      DeleteEndedAuctionsWorker.perform_async(listing_ids)
      record_incr(:jobs_started)
    end until listing_ids.empty?
  end
end
