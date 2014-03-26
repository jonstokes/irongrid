class RssWorker < CoreWorker
  include PageUtils

  sidekiq_options :queue => :crawls, :retry => true

  attr_reader :site

  def init(opts)
    opts.symbolize_keys!
    return false unless @domain = opts[:domain]

    @site = Site.new(domain: @domain)
    track(links_created: 0)
    @link_store = LinkQueue.new(domain: @domain)
    @rate_limiter = RateLimiter.new(@site.rate_limit)
    @links = Set.new
    notify "Checking RSS feed urls with rate limit #{@site.rate_limit}..."
    true
  end

  def perform(opts)
    return unless opts && init(opts)
    feed_urls.each do |feed_url|
      next unless xml = @rate_limiter.with_limit { Nokogiri::XML(open_link(feed_url)) }
      (xml / "link").each do |link|
        url = link.text
        next if ["https://#{site.domain}/", "http://#{site.domain}"].include?(url)
        next unless LinkData.create(url: url)
        @link_store.push(url)
        record_incr(:links_created)
      end
    end

    clean_up
    transition
  end

  def clean_up
    @site.mark_read!
    stop_tracking
    notify "Added #{@record.links_created} links from feed."
  end

  def transition
    ScrapePagesWorker.perform_async(domain: @site.domain)
  end

  private
  def feed_urls
    site.service_options["feed_urls"] || [site.service_options["feed_url"]]
  end


end
