class CreateLinksWorker < CoreWorker
  include PageUtils

  attr_reader :site, :http, :domain
  sidekiq_options :queue => :crawls, :retry => false

  def init(opts)
    return unless opts
    opts.symbolize_keys!
    return false unless (@domain = opts[:domain])

    @http = PageUtils::HTTP.new
    @links_to_add_to_store = Set.new
    @site = opts[:site] || Site.new(domain: domain, source: :redis)
    @rate_limiter = RateLimiter.new(@site.rate_limit)
    @link_store = opts[:link_store] || LinkSet.new(domain: domain)
    record_opts = opts[:record] || {
      links_crawled: 0,
      links_created: 0,
    }
    track(record_opts)
    true
  end

  def perform(opts)
    return unless init(opts)
    notify "Running #{link_list.size} links with rate limit #{@site.rate_limit}..."
    link_list.each do |link|
      pull_product_links_from_seed(link).each { |url| @links_to_add_to_store << url }
    end
    notify "Adding #{@links_to_add_to_store.size} product links to link store..."
    record_set :links_created, @link_store.add(links_to_add_to_store)
    notify "#{@record.links_created} links added to link store."
    clean_up
    transition unless @link_store.empty?
  end

  def clean_up
    stop_tracking
    @site.mark_read!
  end

  def transition
    ScrapePagesWorker.perform_async(domain: domain)
  end

  def pull_product_links_from_seed(link)
    record_incr(:links_crawled)
    links = []
    return links unless page = @rate_limiter.with_limit { get_page(link) }
    xpaths = links_with_attrs[link]["link_xpaths"]
    xpaths.each { |xpath| links += page.doc.xpath(xpath) unless page.doc.at_xpath(xpath).nil? }
    links.flatten.compact.map { |product_link| "#{links_with_attrs[link]["link_prefix"]}#{product_link}".sub(/^https/, "http") }.uniq
  end

  def links_to_add_to_store
    @links_to_add_to_store.to_a
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
