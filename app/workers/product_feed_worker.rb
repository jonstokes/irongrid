class ProductFeedWorker < CoreWorker
  include UpdateImage
  include Trackable

  LOG_RECORD_SCHEMA = {
    db_writes:        Integer,
    images_added:     Integer,
    links_created:    Integer,
    transition:       String,
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
    @http = PageUtils::HTTP.new
    @image_store = ImageQueue.new(domain: @site.domain)
    notify "Checking affiliate feed urls for #{@site.name}..."
    true
  end

  def perform(opts)
    return unless opts && init(opts)
    return CreateLinksWorker.perform_async(domain: @site.domain) unless @site.feeds.any? # Hand off to the legacy CreateLinksWorker
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
      else
        add_links_from_feed(feed)
      end
      feed.clear!
    end
  end

  def clean_up
    notify "Added #{record[:data][:db_writes]} products from feed."
    @site.mark_read!
  end

  def transition
    return if @link_store.empty? || PruneLinksWorker.jobs_in_flight_with_domain(@site.domain).any?
    next_jid = PruneLinksWorker.perform_async(domain: @site.domain)
    record_set(:transition, "PruneLinksWorker")
    record_set(:next_jid, next_jid)
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

  def create_or_update_listing(product)
    scraper = ParsePage.perform(
      site: @site,
      doc: product[:doc],
      url: product[:url],
      adapter_type: :feed
    )
    unless scraper.is_valid?
      notify "Error: Found invalid product: #{product}" unless scraper.not_found?
      return
    end
    update_image(scraper)
    msg = LinkMessage.new(scraper)
    @link_store.rem(msg.url) # Just in case RefreshLinksWorker had added this url to the LinkMessageQueue
    WriteListingWorker.perform_async(msg.to_h)
  end
end
