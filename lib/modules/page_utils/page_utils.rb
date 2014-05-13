module PageUtils
  MAX_RETRIES = 5

  def get_page(link, opts={})
    @http ||= PageUtils::HTTP.new
    page = nil
    begin
      tries ||= MAX_RETRIES
      page = @http.fetch_page(link, opts)
      sleep 0.5
    end until page.try(:doc) || (tries -= 1).zero?
    return if page.nil? || page.not_found? || !page.body.present? || !page.doc
    page
  end

  class Test
    extend PageUtils

    def self.scrape_page(opts)
      url = opts[:url]
      domain = opts[:domain] || URI(url).host
      page = get_page(url)
      site = Site.new(domain: domain, source: :local)
      scraper = ListingScraper.new(site)
      scraper.parse(doc: page.doc, url: url)
      scraper
    end

    def self.get_image(url)
      image = Image.new(source: image_source, http: PageUtils::HTTP.new)
      image.send(:download_image)
      image
    end

    def self.fetch_page(link, opts={})
      get_page(link, opts)
    end
  end
end
