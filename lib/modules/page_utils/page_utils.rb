module PageUtils

  def open_link(raw_url, source=true)
    #FIXME: This is hideous. At the very least the args should be an opts hash.

    file = nil
    url = raw_url.sub("https", "http")
    unless file = fetch_link(url)
      file = fetch_link(raw_url)
    end

    if source && file
      html = file.read
      file.close! rescue file.close
      return html
    else
      return file
    end
  end

  def fetch_link(url)
    retries = 0
    begin
      open(url)
    rescue Exception => e
      Rails.logger.debug "Failed to open #{url} Retries: #{retries}. Message: #{e.message}"
      retries += 1
      sleep 1
      retry if retries < MAX_RETRIES
      nil
    end
  end

  def get_page(link)
    page = nil
    begin
      tries ||= 5
      page = @http.fetch_page(link)
      page.headers.merge!("content-type" => ["text/html"]) if Rails.env.test?
      sleep 0.5
    end until (page && page.doc) || (tries -= 1).zero?
    return nil unless page && page.doc && page.body && !page.not_found?
    page
  end

  def parse_source(opts)
    html, url = opts[:html], opts[:url].to_s
    format = opts[:format] || :universal
    doc = nil
    retries = 0
    begin
      doc = case format
            when :universal
              Nokogiri.parse(html, url)
            when :html
              Nokogiri::HTML(html, url)
            when :xml
              Nokogiri::XML(html, url)
            end
    rescue java.lang.ArrayIndexOutOfBoundsException => e
      retries += 1
      retry if retries < MAX_RETRIES
    rescue ArgumentError => e
      if e.message["invalid byte sequence"]
        parse_type = (parse_type == :html) ? :xml : :html
      end
      retries += 1
      retry if retries < MAX_RETRIES
    rescue Exception => e
      puts "#{e.message}"
      sleep 0.05
      retries += 1
      Rails.logger.debug "Nokogiri failed to parse #{opts[:url]}. Retries: #{retries}. Message #{e.message}"
      retry if retries < MAX_RETRIES
    end
    return doc
  end

  # Testing functions
  #

  def self.open_link(raw_url, source=true)
    file = nil
    retries = 0
    url = raw_url.sub("https", "http")
    begin
      file = open(url)
    rescue Exception => e
      Rails.logger.debug "Failed to open #{url} Retries: #{retries}. Message: #{e.message}"
      retries += 1
      sleep 1
      retry if retries < MAX_RETRIES
    end

    if source && file
      html = file.read
      file.close! rescue file.close
      return html
    else
      return file
    end
  end

  def self.parse_source(opts)
    doc = nil
    retries = 0
    begin
      doc = Nokogiri.parse(opts[:html], opts[:url].to_s)
    rescue java.lang.ArrayIndexOutOfBoundsException => e
      retries += 1
      retry if retries < MAX_RETRIES
    rescue Exception => e
      sleep 1
      retries += 1
      Rails.logger.debug "Nokogiri failed to parse #{url}. Retries: #{retries}. Message #{e.message}"
      retry if retries < MAX_RETRIES
    end
    return doc
  end


  def self.test_scrape(url)
    domain = URI(url).host
    site = Site.find_by_domain domain
    source = open_link(url)
    doc = parse_source(url: url, html: source)
    page = ListingScraper.new(site)
    page.parse(doc: doc, url: url)
    page
  end

  def self.test_categorize(url, slop=1)
    scraper = scrape(url)
    search = Listing.search do
      fulltext scraper.listing["title"] do
        query_phrase_slop(slop)
      end
      facet(:category1)
    end
    category_hash = {}
    search.facet(:category1).rows.each do |row|
      next if row.value == "None"
      category_hash.merge!(row.value => row.count)
    end
    if category_hash.any?
      categories = category_hash.sort_by { |k,v| v }
      return categories.first.first
    else
      return "None"
    end
  end

  def self.spot_check_listing(url)
    listing = Listing.find_by_url(url)
    http = PageUtils::HTTP.new
    site = Site.find_by_domain(URI(url).host)
    scraper = ListingScraper.new(site)

    unless page = get_page(listing.url)
      puts "URL is invalid, so delete."
      return
    end

    scraper.parse(doc: page.doc)
    if scraper.is_valid?
      puts "Listing is valid, so update"
    elsif scraper.classified_sold? || scraper.not_found?
      puts "Should delete"
    else
      puts "Mark inactive."
    end
    page = nil
  end

  def spot_check_link(url)
    @http = PageUtils::HTTP.new
    site = Site.find_by_domain(URI(url).host)
    scraper = ListingScraper.new(site)
    unless page = get_page(url)
      puts "Couldn't fetch page."
      return
    end
    scraper.parse(doc: page.doc)
    if scraper.is_valid?
      puts "Listing is valid."
      if Listing.find_by_digest(scraper.listing["digest"])
        puts "Digest is duplicated in table!"
      else
        puts "Digest not duplicated."
      end
    elsif scraper.classified_sold?
      puts "Classified sold."
    elsif scraper.not_found?
      puts "Page is not_found"
    else
      puts "Reject."
    end
  end

  def clean_dump_link(url)
    @http = PageUtils::HTTP.new
    site = Site.find_by_domain(URI(url).host)
    scraper = ListingScraper.new(site)
    unless page = get_page(url)
      puts "Couldn't fetch page."
      return
    end
    scraper.parse(doc: page.doc)
    scraper.log
  end

  def raw_dump_link(url)
    @http = PageUtils::HTTP.new
    site = Site.find_by_domain(URI(url).host)
    scraper = ListingScraper.new(site)
    unless page = get_page(url)
      puts "Couldn't fetch page."
      return
    end
    scraper.parse(doc: page.doc)
    scraper.raw_log
  end



end
