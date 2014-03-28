class CreateLinksWorker < CoreWorker
  include PageUtils

  LOG_RECORD_SCHEMA = {
    links_crawled: Integer,
    links_created: Integer,
    transition:    String
  }

  sidekiq_options :queue => :crawls, :retry => true

  attr_reader :site, :http, :domain

  def init(opts)
    return false unless opts && @domain = opts[:domain]

    @http = PageUtils::HTTP.new
    @link_count = 0
    @site = Site.new(domain: @domain)
    @rate_limiter = RateLimiter.new(@site.rate_limit)
    @link_store = opts[:link_store] || LinkQueue.new(domain: domain)
    track
    true
  end

  def perform(opts)
    opts.symbolize_keys!
    return unless init(opts)

    notify "Running #{link_list.size} links with rate limit #{@site.rate_limit}..."
    link_list.each do |link|
      pull_product_links_from_seed(link).each do |url|
        status_update
        next unless LinkData.create(url: url, jid: jid)
        @link_store.push url
        record_incr(:links_created)
      end
    end
    clean_up
    transition
  end

  def clean_up
    @site.mark_read!
    notify "Created #{@record[:data][:links_created]} product links in LinkQueue..."
  end

  def transition
    if @link_store.any?
      ScrapePagesWorker.perform_async(domain: domain)
      record_set(:transition, "ScrapePagesWorker")
    end
    stop_tracking
  end

  def pull_product_links_from_seed(link)
    record_incr(:links_crawled)
    links = []
    return links unless page = @rate_limiter.with_limit { get_page(link) }
    xpaths = links_with_attrs[link]["link_xpaths"]
    xpaths.each { |xpath| links += page.doc.xpath(xpath) unless page.doc.at_xpath(xpath).nil? }
    links.flatten.compact.map { |product_link| "#{links_with_attrs[link]["link_prefix"]}#{product_link}".sub(/^https/, "http") }.uniq
  end

  def link_list
    @link_list ||= (seed_links.keys + compressed_links.keys).flatten
  end

  def links_with_attrs
    @links_with_attrs ||= seed_links.merge(compressed_links)
  end

  def seed_links
    @seed_links ||= @site.service_options["seed_links"] || {}
  end

  def compressed_links
    return @compressed_links if @compressed_links
    @compressed_links = {}
    return @compressed_links unless @site.service_options["compressed_links"]
    @site.service_options["compressed_links"].each do |link, attrs|
      interval = attrs["step"] || 1
      (attrs["start_at_page"]..attrs["stop_at_page"]).step(interval).each do |page_number|
        @compressed_links.merge!(link.sub("PAGENUM", page_number.to_s) => attrs)
      end
    end
    @compressed_links
  end
end
