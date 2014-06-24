require 'page_utils/page'
require 'capybara/poltergeist'

module PageUtils
  class DynamicHTTP

    #
    # Create new Pages from the response of an HTTP request to *url*,
    # including redirects
    #
    def fetch_page(url, opts={})
      force_format = opts[:force_format]
      $session_pool.with do |session|
        begin
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
        ensure
          session.reset!
        end
      end
    end
  end
end
