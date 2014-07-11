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

  def render_page(link, opts={})
    @dhttp ||= PageUtils::DynamicHTTP.new
    begin
      tries ||= 3
      page = @dhttp.fetch_page(link, opts)
      sleep 1
    end until page.try(:code) && page.try(:doc) || (tries -= 1).zero?
    return if page.nil? || (page.url == "about:blank") || page.not_found? || !page.body.present? || !page.doc
    page
  end

  def close_http_connections
    @http.close if @http
    @dhttp.close if @dhttp
  rescue IOError
  end

  class Test
    extend PageUtils

    def self.scrape_page(opts)
      url = opts[:url]
      domain = opts[:domain] || URI(url).host
      return unless page = get_page(url, force_format: :html)
      site = Site.new(domain: domain, source: :local)
      ParsePage.perform(
        site: site,
        page: page,
        url: url,
        adapter_type: :page
      )
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
