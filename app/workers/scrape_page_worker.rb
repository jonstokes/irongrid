class ScrapePageWorker < CoreWorker
  include PageUtils

  sidekiq_options :queue => :scrapes, :retry => false

  attr_reader :domain, :site, :url

  def init(opts)
    opts.to_h.symbolize_keys!
    return false unless opts && (@domain = opts[:domain]) && (@url = opts[:url])
    @site = Site.new(
      domain: domain,
      pool:   opts[:site_pool].try(:to_sym),
      source: opts[:site_source].try(:to_sym)
    )
    true
  end

  def perform(opts)
    return unless opts && init(opts)
    return unless @site.page_adapter
    pull_and_process(url)
    @dhttp.destroy! if @dhttp
  end

  private

  def pull_and_process(url)
    if scraper = scrape_page(url)
      msg = LinkMessage.new(
        url:                  url,
        page_is_valid:        scraper.is_valid?,
        page_not_found:       scraper.not_found?,
        page_classified_sold: scraper.classified_sold?,
        page_attributes:      scraper.listing,
        raw_attributes:       scraper.raw_listing
      )
    else
      msg = LinkMessage.new(url: url, page_not_found: true)
    end
    ValidatorQueue.add(jid, msg.to_h)
  end

  def scrape_page(url)
    return unless page = fetch_page(url)
    ParsePage.perform(
      site: @site,
      page: page,
      url: url,
      adapter_type: :page
    )
  end

  def fetch_page(url)
    if @site.page_adapter['format'] ==  'dhtml'
      render_page(url)
    else
      get_page(url)
    end
  end
end
