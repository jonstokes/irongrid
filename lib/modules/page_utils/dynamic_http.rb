require 'page_utils/page'
require 'capybara/poltergeist'

module PageUtils
  class DynamicHTTP

    def initialize(opts = {})
      @opts = opts
    end

    #
    # Create new Pages from the response of an HTTP request to *url*,
    # including redirects
    #
    def fetch_page(url, opts={})
      force_format = opts[:force_format]
      BROWSER_POOL.with do |session|
        session.reset!
        session.visit(url.to_s)
        page = PageUtils::Page.new(
          session.current_url,
          :body => session.html.dup,
          :code => session.status_code,
          :headers => session.response_headers,
          :force_format => force_format
        )

        return page
      rescue Exception => e
        return Page.new(url, :error => e)
      end
    end

    #
    # The user-agent string which will be sent with each request,
    # or nil if no such option is set
    #
    def user_agent
      "Mozilla/5.0 (Macintosh; Intel Mac OS X)"
    end

    #
    # Does this HTTP client accept cookies from the server?
    #
    def accept_cookies?
      @opts[:accept_cookies]
    end

    #
    # The proxy address string
    #
    def proxy_host
      @opts[:proxy_host]
    end

    #
    # The proxy port
    #
    def proxy_port
      @opts[:proxy_port]
    end

    #
    # HTTP read timeout in seconds
    #
    def read_timeout
      @opts[:read_timeout]
    end
  end
end
