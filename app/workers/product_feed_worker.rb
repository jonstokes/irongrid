class ProductFeedWorker < CoreWorker
  include UpdateImage
  include Trackable

  LOG_RECORD_SCHEMA = {
    db_writes:        Integer,
    images_added:     Integer,
    links_created:    Integer
  }

  sidekiq_options :queue => :crawls, :retry => false

  attr_reader :site, :page_queue

  def init(opts)
    opts.symbolize_keys!
    return false unless @domain = opts[:domain]
    @filename = opts[:filename]
    @site = opts[:site] || Site.new(domain: @domain)
    @scraper = ListingScraper.new(site)
    @http = PageUtils::HTTP.new
    @image_store = ImageQueue.new(domain: @site.domain)
    notify "Checking affiliate feed urls for #{@site.name}..."
    true
  end

  def perform(opts)
    return unless opts && init(opts)
    return transition unless @site.feeds # This hands off to the legacy CreateLinksWorker
    track
    check_feeds
    clean_up
    stop_tracking
  end

  def check_feeds
    site.feeds.each do |feed|
      if feed.products.any?
        create_or_update_products_from_feed(feed)
      else
        add_links_from_feed(feed)
      end
    end
  end

  def clean_up
    notify "Added #{record[:data][:db_writes]} links from feed."
    @site.mark_read!
  end

  def transition
    CreateLinksWorker.new(domain: @site.domain)
  end

  def create_or_update_products_from_feed(feed)
    notify "  Checking feed #{feed.feed_url} with #{feed.products.count} products..."
    feed.each_product do |product|
      create_or_update_listing(product)
      record_incr(:db_writes)
    end
  end

  def add_links_from_feed(feed)
    notify "  Checking feed #{feed.feed_url} with #{feed.links.count} links..."
    feed.each_link do |link|
      record_incr(:links_created) unless @link_store.add(LinkMessage.new(url: link)).zero?
    end
  end

  def create_or_update_listing(opts)
    @scraper.parse(opts.merge(adapter_type: :feed))
    update_image
    msg = LinkMessage.new(@scraper)
    @link_store.rem(msg.url) # Just in case RefreshLinksWorker had added this url to the LinkMessageQueue
    WriteListingWorker.perform_async(msg.to_h)
    @scraper.empty!
  end
end
