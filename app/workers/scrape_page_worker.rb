class ScrapePageWorker < CoreWorker
  include PageUtils

  sidekiq_options :queue => :scrapes, :retry => false

  attr_reader :domain, :site, :url

  def initialize
    @http = PageUtils::HTTP.new
  end

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
    pull_and_process(url)
  end

  private

  def pull_and_process(url)
    if @site.page_adapter && page = get_page(url)
      scraper = ParsePage.perform(
        site: @site,
        page: page,
        url: url,
        adapter_type: :page
      )
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
    notify "### My JID is #{jid}"
    ValidatorQueue.add(jid, msg.to_h)
  end
end
