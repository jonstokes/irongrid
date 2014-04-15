class RssWorker < CoreWorker
  include PageUtils
  include Trackable

  LOG_RECORD_SCHEMA = {
    links_created: Integer,
    transition:    String,
    next_jid:      String
  }

  sidekiq_options :queue => :crawls, :retry => false

  attr_reader :site

  def init(opts)
    opts.symbolize_keys!
    return false unless @domain = opts[:domain]

    @site = Site.new(domain: @domain)
    track
    @link_store = LinkQueue.new(domain: @domain)
    @rate_limiter = RateLimiter.new(@site.rate_limit)
    @links = Set.new
    notify "Checking RSS feed urls with rate limit #{@site.rate_limit}..."
    true
  end

  def perform(opts)
    return unless opts && init(opts)
    feed_urls.each do |feed_url|
      next unless xml = @rate_limiter.with_limit { Nokogiri::XML(get_page(feed_url).body) rescue nil }
      (xml / "link").each do |link|
        url = link.text
        next if ["https://#{site.domain}/", "http://#{site.domain}"].include?(url)
        next unless @link_store.add(url)
        LinkData.create(url: url)
        record_incr(:links_created)
      end
    end

    clean_up
    transition
    stop_tracking
  end

  def clean_up
    @site.mark_read!
    notify "Added #{@record[:data][:links_created]} links from feed."
  end

  def transition
    return if @link_store.empty?
    next_jid = PruneLinksWorker.perform_async(domain: @site.domain)
    record_set(:transition, "PruneLinksWorker")
    record_set(:next_jid, next_jid)
  end

  private
  def feed_urls
    site.service_options["feed_urls"] || [site.service_options["feed_url"]]
  end
end
