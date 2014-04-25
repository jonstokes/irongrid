class LinkFeedWorker < CoreWorker
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
    @filename = opts[:filename]
    @feed_url = opts[:feed_url]
    @site = opts[:site] || Site.new(domain: @domain)
    @service_options = @site.service_options
    @link_store = LinkMessageQueue.new(domain: @domain)
    @rate_limiter = RateLimiter.new(@site.rate_limit)
    @links = Set.new
    notify "Checking RSS feed urls with rate limit #{@site.rate_limit}..."
    true
  end

  def perform(opts)
    return unless opts && init(opts)
    track
    feeds.each do |feed|
      feed.each_product do |product|
        next unless product[:url]
        next if ["https://#{site.domain}/", "http://#{site.domain}"].include?(product[:url])
        next if @link_store.add(LinkMessage.new(url: product[:url])).zero?
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
  def feeds
    @feeds ||= @service_options["feeds"].map do |feed_opts|
      feed_opts.merge!(filename: @filename, feed_url: @feed_url)
      Feed.new(feed_opts)
    end
  end
end
