class ProductFeedWorker < CoreWorker
  include UpdateImage
  include Trackable

  LOG_RECORD_SCHEMA = {
    db_writes:        Integer,
    images_added:     Integer,
    listings_deleted: Integer
  }


  sidekiq_options :queue => :crawls, :retry => false

  attr_reader :site, :page_queue

  def init(opts)
    opts.symbolize_keys!
    return false unless @domain = opts[:domain]
    @filename = opts[:filename]
    @feed_url = opts[:feed_url]
    @site = opts[:site] || Site.new(domain: @domain)
    @service_options = @site.service_options
    @scraper = ListingScraper.new(site)
    @http = PageUtils::HTTP.new
    @image_store = ImageQueue.new(domain: @site.domain)
    notify "Checking affiliate feed urls for #{@site.name}..."
    true
  end

  def perform(opts)
    return unless opts && init(opts)
    track
    feeds.each do |feed|
      create_update_or_delete_products(feed)
    end
    clean_up
    stop_tracking
  end

  def clean_up
    notify "Added #{record[:data][:db_writes]} links from feed."
    @site.mark_read!
  end

  def create_update_or_delete_products(feed)
    notify "  Checking feed #{feed.feed_url} with #{feed.product_count} items..."
    feed.each_product do |product|
      action = :no_action
      if (product[:status] == "Removed")
        action = delete_listing(product[:url])
      else
        action = create_or_update_listing(product)
      end
      record_incr(:db_writes)
    end
  end

  def create_or_update_listing(opts)
    @scraper.parse(opts)
    return :invalid unless @scraper.is_valid?
    url = opts[:url]
    update_image
    msg = LinkMessage.new(
      url: url,
      page_is_valid: true,
      page_not_found: false,
      page_attributes: @scraper.listing
    )
    WriteListingWorker.perform_async(msg.to_h)
    :created_or_updated
  end

  def delete_listing(url)
    record_incr(:listings_deleted)
    msg = LinkMessage.new(
      url: url,
      page_is_valid: false,
      page_not_found: true,
      page_attributes: nil
    )
    WriteListingWorker.perform_async(msg.to_h)
    :deleted
  end

  def feeds
    @feeds ||= @service_options["feeds"].map do |feed_opts|
      feed_opts.merge!(filename: @filename, feed_url: @feed_url)
      Feed.new(feed_opts)
    end
  end
end
