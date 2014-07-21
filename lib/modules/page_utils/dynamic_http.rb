require 'page_utils/page'
require 'capybara/poltergeist'

module PageUtils
  class DynamicHTTP
    include Notifier

    attr_reader :session

    def initialize(opts = {})
      @opts = opts
      new_session
    end

    def close
      @session.driver.quit
    end

    def new_session
      Capybara.register_driver :poltergeist do |app|
        Capybara::Poltergeist::Driver.new(
          app,
          js_errors: false,
          phantomjs_options: ['--load-images=no', '--ignore-ssl-errors=yes']
        )
      end
      Capybara.default_driver = :poltergeist
      Capybara.javascript_driver = :poltergeist
      Capybara.run_server = false
      @session = Capybara::Session.new(:poltergeist)
      @session.driver.headers = { 'User-Agent' => "Mozilla/5.0 (Macintosh; Intel Mac OS X)" }
      @session
    end

    def restart_session
      close
      new_session
    end

    #
    # Create new Pages from the response of an HTTP request to *url*,
    # including redirects
    #
    def fetch_page(url, opts={})
      begin
        tries ||= 5
        get_page(url, opts)
      rescue Capybara::Poltergeist::DeadClient, Errno::EPIPE, NoMethodError, Capybara::Poltergeist::BrowserError => e
        restart_session
        retry unless (tries -= 1).zero?
        close
        raise e
      end
    end

    def get_page(url, opts)
      session.visit(url.to_s)
      return PageUtils::Page.new(
        session.current_url,
        :body => session.html.dup,
        :code => session.status_code,
        :headers => session.response_headers,
        :force_format => opts[:force_format]
      )
    rescue Capybara::Poltergeist::TimeoutError => e
      return Page.new(url, :error => e)
    ensure
      session.reset!
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
