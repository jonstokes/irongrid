class AvantlinkWorker < ProductFeedWorker
  sidekiq_options :queue => :utils, :retry => false

  attr_reader :site, :page_queue

  def perform(opts)
    return unless opts && init(opts)
    track
    check_feeds
    clean_up
    stop_tracking
  end

  def clean_up
    notify "Added #{record[:data][:db_writes]} products from feed."
  end

  def create_or_update_listing(product)
    scraper = ParsePage.perform(
      site: @site,
      doc: product[:doc],
      url: product[:url],
      adapter_type: :feed
    )
    unless scraper.is_valid?
      notify "Error: Found invalid product: #{product}"
      return
    end
    update_image(scraper)
    msg = LinkMessage.new(scraper)
    @link_store.rem(msg.url) # Just in case RefreshLinksWorker had added this url to the LinkMessageQueue
    write_listing(msg)
  end

  def write_listing(msg)
    if listing = db { Listing.find_by_url(msg.url) }
      update_listing(msg, listing)
    else
      new_listing(msg)
    end
  end

  def update_listing(msg, listing)
    update_geo_data(msg)
    listing.update_with_count(msg.page_attributes)
  end

  def new_listing(msg)
    return if db { Listing.find_by_digest(msg.page_attributes["digest"]) }
    klass = eval msg.page_attributes["type"]
    update_geo_data(msg)
    db { klass.create(msg.page_attributes) }
  rescue ActiveRecord::RecordNotUnique
    notify "Listing not unique for message #{msg.to_h}", type: :error
    return
  end
end
