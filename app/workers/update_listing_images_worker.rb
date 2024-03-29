class UpdateListingImagesWorker < BaseWorker

  sidekiq_options queue: :db_slow_low, retry: true

  track_with_schema(
    listings_updated: Integer,
  )

  before :should_run?, :track
  after :stop_tracking

  def listing_ids
    @context
  end

  def call
    listing_ids.each do |id|
      next unless results = IronBase::Listing.find(id)
      listing = results.hits.first
      update_listing(listing) && next unless listing.image.source.try(:present?)

      image = CDN::Image.new(source: listing.image.source)
      if image.exists?
        listing.image.cdn = image.cdn_url
        update_listing(listing)
      end
    end
  end

  def should_run?
    listing_ids.try(:any?) || abort!
  end

  private

  def update_listing(listing)
    listing.image.download_attempted = true
    listing.update_record_without_timestamping
    record_incr(:listings_updated)
  end
end
