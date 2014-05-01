class CreateLinksWorker < CoreWorker
  include PageUtils
  include Trackable

  LOG_RECORD_SCHEMA = {
    links_crawled: Integer,
    links_created: Integer,
    transition:    String,
    next_jid:      String
  }

  sidekiq_options :queue => :crawls, :retry => false

  attr_reader :site, :http, :domain

  def init(opts)
    opts.symbolize_keys!
    return false unless opts && @domain = opts[:domain]
    return false if ScrapePagesWorker.jobs_in_flight_with_domain(@domain).any?
    @http = PageUtils::HTTP.new
    @link_count = 0
    @site = Site.new(domain: @domain)
    @rate_limiter = RateLimiter.new(@site.rate_limit)
    @link_store = opts[:link_store] || LinkMessageQueue.new(domain: domain)
    true
  end

  def perform(opts)
    return unless opts && init(opts)
    track
    notify "Running #{link_list.size} links with rate limit #{@site.rate_limit}..."
    link_list.each do |link|
      pull_product_links_from_seed(link).each do |url|
        status_update
        next unless @link_store.add(LinkMessage.new(url: url)).zero?
        record_incr(:links_created)
      end
    end
    clean_up
    transition
    stop_tracking
  end

  def clean_up
    @site.mark_read!
    notify "Created #{@record[:data][:links_created]} product links in LinkMessageQueue..."
  end

  def transition
    return if @link_store.empty?
    next_jid = PruneLinksWorker.perform_async(domain: domain)
    record_set(:transition, "PruneLinksWorker")
    record_set(:next_jid, next_jid)
  end

  def pull_product_links_from_seed(seed_link)
    return [] unless page = @rate_limiter.with_limit do
      get_page(seed_link, force_format: @site.link_list_format)
    end
    record_incr(:links_crawled)
    links_in_page(page).flatten.compact.map do |product_link|
      "#{link_prefix(seed_link)}#{product_link.text}".sub(/^https/, "http")
    end.uniq
  end

  def links_in_page(page)
    link_xpaths(page.url.to_s).map do |xpath|
      page.doc.xpath(xpath) unless page.doc.at_xpath(xpath).nil?
    end.compact.flatten
  end

  def link_list
    @link_list ||= (seed_links.keys + compressed_links.keys).flatten
  end

  def link_prefix(link)
    links_with_attrs[link]["link_prefix"]
  end

  def link_xpaths(link)
    links_with_attrs[link]["link_xpaths"]
  end

  def links_with_attrs
    @links_with_attrs ||= seed_links.merge(compressed_links)
  end

  def seed_links
    @seed_links ||= @site.link_sources["seed_links"] || {}
  end

  def compressed_links
    return @compressed_links if @compressed_links
    @compressed_links = {}
    return @compressed_links unless @site.link_sources["compressed_links"]
    @site.link_sources["compressed_links"].each do |link, attrs|
      interval = attrs["step"] || 1
      (attrs["start_at_page"]..attrs["stop_at_page"]).step(interval).each do |page_number|
        @compressed_links.merge!(link.sub("PAGENUM", page_number.to_s) => attrs)
      end
    end
    @compressed_links
  end
end
