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

    def quit!
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

    #
    # Create new Pages from the response of an HTTP request to *url*,
    # including redirects
    #
    def fetch_page(url, opts={})
      force_format = opts[:force_format]
      begin
        tries ||= 5
        session.visit(url.to_s)
        page = PageUtils::Page.new(
          session.current_url,
          :body => session.html.dup,
          :code => session.status_code,
          :headers => session.response_headers,
          :force_format => force_format
        )
        session.reset!
        return page
      rescue Capybara::Poltergeist::TimeoutError, Capybara::Poltergeist::DeadClient, Errno::EPIPE => e
        quit!
        new_session
        notify "### Error: #{clean_error(e)}. Retrying with #{phantomjs_count} phantomjs instances running."
        retry unless (tries -= 1).zero?
        quit!
        raise e
      end
    end

    def clean_error(e)
      backtrace = e.backtrace.select { |line| !!line["home/bitnami/irongrid"] }
      "#{e} #{backtrace}"
    end

    def phantomjs_count
      `ps aux | grep phantomjs | wc -l`.strip
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
