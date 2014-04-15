module PageUtils
  MAX_RETRIES = 5

  def open_link(raw_url, source=true)
    #FIXME: This is hideous. At the very least the args should be an opts hash.

    file = nil
    url = raw_url
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
    retries = MAX_RETRIES
    begin
      open(url)
    rescue Exception => e
      Rails.logger.debug "Failed to open #{url} Retries: #{retries}. Message: #{e.message}"
      sleep 1
      retry if (retries -= 1).zero?
      nil
    end
  end

  def get_page(link)
    @http ||= PageUtils::HTTP.new
    page = nil
    begin
      tries ||= 5
      page = @http.fetch_page(link)
      #page.headers.merge!("content-type" => ["text/html"]) if Rails.env.test?
      sleep 0.5
    end until page.try(:doc) || (tries -= 1).zero?
    return if page.nil? || page.not_found? || !page.body.present? || !page.doc
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
end
