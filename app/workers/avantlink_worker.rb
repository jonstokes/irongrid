class AvantlinkWorker < CoreWorker
  include UpdateImage
  include Trackable

  LOG_RECORD_SCHEMA = {
    db_writes:        Integer,
    images_added:     Integer,
    listings_deleted: Integer
  }


  sidekiq_options :queue => :crawls, :retry => false

  attr_reader :site, :page_queue

  class Feed
    include PageUtils
    include Notifier
    attr_reader :options

    def initialize(opts)
      #NOTE: The :filename option is for the affiliate_setup rake task, when
      # a seller's complete inventory is first loaded into the db from
      # a large local xml file. Later updates come via the feed url
      @options = opts[:feed_options]
      @filename = opts[:filename]
      @feed_url = opts[:feed_url]
    end

    def each_product
      parsed_xml.xpath(list_xpath).each_with_index do |product, i|
        product_hash = {
          url:    product.xpath(link_xpath)[i].try(:text),
          status: product.xpath(status_xpath)[i].try(:text),
          xml:    product_xml(product)
        }
        yield product_hash
      end
    end

    def product_count
      parsed_xml.xpath(list_xpath).count
    end

    def empty?
      parsed_xml.xpath(list_xpath).empty?
    end

    def feed_url
      return nil if @filename
      @feed_url ||= options["postfix"] ? (options["url"] + eval(options["postfix"])) : options["url"]
    end

    def xml_data
      @xml_data ||= begin
        notify "  Downloading #{feed_url || @filename}..."
        data = @filename ? File.open(@filename).read : get_page(feed_url).body
        notify "  Feed downloaded from #{feed_url || @filename}!"
        data
      end
    end

    def parsed_xml
      return @parsed_xml if @parsed_xml
      notify "  Parsing #{feed_url || @filename}..."
      @parsed_xml ||= Nokogiri::XML(xml_data)
      notify "  Feed parsed from #{feed_url || @filename}!"
      @parsed_xml
    end

    def list_xpath
      options["product_list_xpath"]
    end

    def link_xpath
      options["product_link_xpath"]
    end

    def status_xpath
      options["product_status_xpath"]
    end

    def product_xml(product)
      return unless product
      xml_prefix = '<?xml version="1.0" encoding="us-ascii"?>' + "\n"
      xml_prefix + product.to_xml
    end
  end

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
      create_update_or_delete_products(feed) unless feed.empty?
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
      next unless product[:xml]
      action = :no_action
      record_incr(:db_writes)
      if (product[:status] == "Removed")
        action = delete_listing(product[:url])
      else (product[:status] == "Modified")
        action = create_or_update_listing(url: product[:url], doc: Nokogiri::XML(product[:xml]))
      end
      notify "Product #{product[:url]} | Status #{product[:status]} | Action: #{action}"
    end
  end

  def create_or_update_listing(opts)
    @scraper.parse(opts)
    return :invalid unless @scraper.is_valid?
    url = opts[:url]
    update_image
    LinkData.create(
      url: url,
      page_is_valid: true,
      page_not_found: false,
      page_attributes: @scraper.listing
    )
    WriteListingWorker.perform_async(url)
    :created_or_updated
  end

  def delete_listing(url)
    record_incr(:listings_deleted)
    LinkData.create(
      url: url,
      page_is_valid: false,
      page_not_found: true,
      page_attributes: nil
    )
    WriteListingWorker.perform_async(url)
    :deleted
  end

  def feeds
    @feeds ||= @service_options["feeds"].map do |feed_opts|
      AvantlinkWorker::Feed.new(
        feed_options: feed_opts,
        filename: @filename,
        feed_url: @feed_url
      )
    end
  end
end
