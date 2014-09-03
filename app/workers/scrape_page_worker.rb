class ScrapePageWorker < CoreWorker
  include PageUtils

  sidekiq_options :queue => :scrapes, :retry => false

  attr_reader :domain, :site, :session, :domain

  def init(opts)
    opts.to_h.symbolize_keys!
    return false unless opts && @domain = opts[:domain]
    return false unless opts[:session] && @session = Stretched::Session.new(opts[:session])
    @site = Site.new(
      domain: domain,
      pool:   opts[:site_pool].try(:to_sym),
      source: opts[:site_source].try(:to_sym)
    )
    true
  end

  def perform(opts)
    return unless opts && init(opts)
    Stretched::RunSession.perform(session)
    results = {}
    session.object_adapters.each do |adapter|
      scrapes = pull_and_process(adapter.queue)
      results.merge!(adapter.queue => scrapes)
    end
    ValidatorQueue.add(jid, results)
  ensure
    close_http_connections
  end

  private

  def pull_and_process(object_queue)
    scrapes = []
    while json = object_queue.pop do
      scrape = { json: json }
      if object_queue.name[/listing/]
        listing = clean_listing(json)
        scrape.merge!(listing: listing)
      end
      # scrape: { json: json, listing: listing }
      scrapes << scrape
    end
    scrapes
  end

  def clean_listing(json)
    scraper = ParseJson.perform(json.merge(site: site))
    scraper.listing
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
