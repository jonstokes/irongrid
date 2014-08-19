require 'nokogiri'
require 'ostruct'
require 'webrick/cookie'

module Stretched
  class Page

    # The URL of the page
    attr_reader :url
    # The raw HTTP response body of the page
    attr_reader :body
    # Headers of the HTTP response
    attr_reader :headers
    # URL of the page this one redirected to, if any
    attr_reader :redirect_to
    # Exception object, if one was raised during HTTP#fetch_page
    attr_reader :error
    # Integer response code of the page
    attr_accessor :code
    # Boolean indicating whether or not this page has been visited in PageStore#shortest_paths!
    attr_accessor :visited
    # Depth of this page from the root of the crawl. This is not necessarily the
    # shortest path; use PageStore#shortest_paths! to find that value.
    attr_accessor :depth
    # URL of the page that brought us to this page
    attr_accessor :referer
    # Response time of the request for this page in milliseconds
    attr_accessor :response_time

    #
    # Create a new page
    #
    def initialize(url, params = {})
      @url = url

      @code = params[:code]
      @headers = params[:headers] || {}
      @headers['content-type'] ||= ['']
      @aliases = Array(params[:aka]).compact
      @referer = params[:referer]
      @depth = params[:depth] || 0
      @redirect_to = to_absolute(params[:redirect_to])
      @response_time = params[:response_time]
      @error = params[:error]
      @fetched = !params[:code].nil?
      @force_format = params[:force_format]
      @body = params[:body]
    end

    #
    # Nokogiri document for the HTML body
    #
    def doc
      @doc ||= begin
        if image?
          nil
        elsif should_parse_as?(:xml)
          Nokogiri::XML(@body, @url.to_s)
        elsif should_parse_as?(:html)
          Nokogiri::HTML(@body, @url.to_s)
        elsif @body
          Nokogiri.parse(@body, @url.to_s)
        end
      end
    end

    def is_valid?
      (url != "about:blank") && !not_found? && present?
    end

    def present?
      !error && !!code && body.present? && !!doc
    end

    #
    # Delete the Nokogiri document and response body to conserve memory
    #
    def discard_doc!
      @doc = @body = nil
    end

    #
    # Was the page successfully fetched?
    # +true+ if the page was fetched with no error, +false+ otherwise.
    #
    def fetched?
      @fetched
    end

    #
    # Array of cookies received with this page as WEBrick::Cookie objects.
    #
    def cookies
      WEBrick::Cookie.parse_set_cookies(@headers['Set-Cookie']) rescue []
    end

    #
    # The content-type returned by the HTTP request for this page
    #
    def content_type
      headers['content-type'].first
    end

    #
    # Returns +true+ if the page is an image, returns +false+
    # otherwise.
    #
    def image?
      !!(content_type =~ %r{^(image/)\b})
    end

    #
    # Returns +true+ if the page is a HTML document, returns +false+
    # otherwise.
    #
    def html?
      !!(content_type =~ %r{^(text/html|application/xhtml+xml)\b})
    end

    #
    # Returns +true+ if the page is a XML document, returns +false+
    # otherwise.
    #
    def xml?
      !!(content_type =~ %r{^(text/xml|application/xml)\b})
    end

    #
    # Returns +true+ if the page is a HTTP redirect, returns +false+
    # otherwise.
    #
    def redirect?
      (300..307).include?(@code)
    end

    #
    # Returns +true+ if the page was not found (returned 404 code),
    # returns +false+ otherwise.
    #
    def not_found?
      404 == @code
    end

    #
    # Base URI from the HTML doc head element
    # http://www.w3.org/TR/html4/struct/links.html#edef-BASE
    #
    def base
      @base = if doc
        href = doc.search('//head/base/@href')
        URI(href.to_s) unless href.nil? rescue nil
      end unless @base
      
      return nil if @base && @base.to_s().empty?
      @base
    end


    #
    # Converts relative URL *link* into an absolute URL based on the
    # location of the page
    #
    def to_absolute(link)
      return nil if link.nil?

      # remove anchor
      link = URI.encode(URI.decode(link.to_s.gsub(/#[a-zA-Z0-9_-]*$/,'')))

      relative = URI(link)
      absolute = base ? base.merge(relative) : @url.merge(relative)

      absolute.path = '/' if absolute.path.empty?

      return absolute
    end

    #
    # Returns +true+ if *uri* is in the same domain as the page, returns
    # +false+ otherwise
    #
    def in_domain?(uri)
      uri.host == @url.host
    end

    def marshal_dump
      [@url, @headers, @body, @links, @code, @visited, @depth, @referer, @redirect_to, @response_time, @fetched]
    end

    def marshal_load(ary)
      @url, @headers, @body, @links, @code, @visited, @depth, @referer, @redirect_to, @response_time, @fetched = ary
    end

    def to_hash
      {'url' => @url.to_s,
       'headers' => Marshal.dump(@headers),
       'body' => @body,
       'code' => @code,
       'visited' => @visited,
       'depth' => @depth,
       'referer' => @referer.to_s,
       'redirect_to' => @redirect_to.to_s,
       'response_time' => @response_time,
       'fetched' => @fetched}
    end

    def self.from_hash(hash)
      page = self.new(URI(hash['url']))
      {'@headers' => Marshal.load(hash['headers']),
       '@body' => hash['body'],
       '@code' => hash['code'].to_i,
       '@visited' => hash['visited'],
       '@depth' => hash['depth'].to_i,
       '@referer' => hash['referer'],
       '@redirect_to' => (!!hash['redirect_to'] && !hash['redirect_to'].empty?) ? URI(hash['redirect_to']) : nil,
       '@response_time' => hash['response_time'].to_i,
       '@fetched' => hash['fetched']
      }.each do |var, value|
        page.instance_variable_set(var, value)
      end
      page
    end

    private

    def cleanup_encoding(source)
      return source unless source && (html? || xml? || @force_format)
      text = source.dup
      text.encode!('UTF-16', 'UTF-8', {:invalid => :replace, :undef => :replace, :replace => '?'})
      text.encode('UTF-8', 'UTF-16')
    end

    def should_parse_as?(format)
      return false unless @body
      return @force_format == format if @force_format
      send("#{format}?")
    end
  end
end
