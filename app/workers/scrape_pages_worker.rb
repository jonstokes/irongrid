class ScrapePagesWorker < CoreWorker
  include PageUtils

  attr_reader :domain, :site
  attr_accessor :timeout if Rails.env.test?

  sidekiq_options :queue => :crawls, :retry => false

  def initialize
    @http = PageUtils::HTTP.new
  end

  def init(opts)
    return false unless opts
    opts.symbolize_keys!
    return false unless @domain = opts[:domain]

    @site = Site.new(domain: domain)
    @scraper = ListingScraper.new(@site)
    @rate_limiter = RateLimiter.new(@site.rate_limit)
    @timeout ||= ((60.0 / site.rate_limit.to_f) * 60).to_i
    @link_store = LinkQueue.new(domain: domain)
    record_opts = {
      pages_created: 0,
      links_deleted: 0
    }
    track(record_opts)
    true
  end

  def perform(opts)
    return unless init(opts)

    notify "Emptying link store..."
    while !timed_out? && (link_data = LinkData.find(@link_store.pop)) do
      link_data.update(jid: self.jid)
      record_incr(:links_deleted)
      @scraper.empty!
      @rate_limiter.with_limit { pull_and_process(link_data) }
    end
    clean_up
    transition
  end

  def clean_up
    notify "Added #{@record.pages_created} from link store."
    stop_tracking
    @site.mark_read!
  end

  def transition
    if @link_store.empty? && @site.should_read?
      RefreshLinksWorker.perform_async(domain: domain)
    else
      self.class.perform_async(domain: domain)
    end
  end

  #
  # private
  #

  def timed_out?
    (@timeout -= 1).zero?
  end

  def pull_and_process(link_data)
    url = link_data.url
    if page = get_page(url)
      @scraper.parse(doc: page.doc, url: url)
      update_image(@scraper) if @scraper.is_valid?
      link_data.update(
        page_is_valid:   @scraper.is_valid?,
        page_not_found:  @scraper.not_found?,
        page_attributes: @scraper.listing
      )
      WriteListingWorker.perform_async(url)
    else
      link_data.update(page_not_found: true)
      WriteListingWorker.perform_async(url)
    end
  end

  def update_image(scraper)
    return unless image_source = scraper.listing["item_data"]["image_source"]
    if CDN.has_image?(image_source)
      scraper.listing["item_data"]["image"] = CDN.url_for_image(image_source)
    else
      ImageQueue.new(domain: domain).push image_source
    end
  end
end
