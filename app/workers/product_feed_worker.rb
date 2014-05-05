class ProductFeedWorker < CoreWorker
  include UpdateImage
  include Trackable

  LOG_RECORD_SCHEMA = {
    db_writes:        Integer,
    images_added:     Integer,
    links_created:    Integer,
    next_jid:         String
  }

  sidekiq_options :queue => :crawls, :retry => false

  attr_reader :site, :page_queue

  def init(opts)
    opts.symbolize_keys!
    return false unless @domain = opts[:domain]
    @filename = opts[:filename]
    @site = opts[:site] || Site.new(domain: @domain)
    @link_store = LinkMessageQueue.new(domain: @domain)
    @scraper = ListingScraper.new(site)
    @http = PageUtils::HTTP.new
    @image_store = ImageQueue.new(domain: @site.domain)
    @next_worker = :CreateLinksWorker
    notify "Checking affiliate feed urls for #{@site.name}..."
    true
  end

  def perform(opts)
    return unless opts && init(opts)
    return transition unless @site.feeds.any? # This hands off to the legacy CreateLinksWorker
    track
    check_feeds
    clean_up
    transition
    stop_tracking
  end

  def check_feeds
    site.feeds.each do |feed|
      if feed.products.any?
        create_or_update_products_from_feed(feed)
        @next_worker = nil
      else
        add_links_from_feed(feed)
        @next_worker = :ScrapePagesWorker
      end
    end
  end

  def clean_up
    notify "Added #{record[:data][:db_writes]} products from feed."
    @site.mark_read!
  end

  def transition
    return unless @next_worker
    klass = @next_worker.to_s.constantize
    next_jid = klass.perform_async(domain: @site.domain)
    record_set(:next_jid, next_jid) if tracking?
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
