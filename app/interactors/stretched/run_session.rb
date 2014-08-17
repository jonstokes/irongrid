module Stretched
  class RunSession
    include Interactor
    include Stretched::PageUtils

    def setup
      Extension.register_all
      Script.register_all
    end

    def perform
      #context: stretched_session, browser_session

      stretched_session.urls.each do |url|
        next unless page = scrape_page(url)
        stretched_session.object_adapters.each do |adapter|
          object_q = ObjectQueue.find_or_create(adapter.queue_name)
          result = ExtractJsonFromPage.perform(
            page: page,
            adapter: adapter,
            browser_session: browser_session
          )
          context[:pages_scraped] = stretched_session.urls.count
          puts "## Scraped #{result.json_objects.count} objects from #{url}"
          object_q.add result.json_objects
        end
      end
    ensure
      close_http_connections
    end

    private

    def browser_session
      return unless @dhttp
      @dhttp.session
    end

    def scrape_page(url)
      if stretched_session.use_phantomjs?
        stretched_session.with_limit { render_page(url) }
      else
        stretched_session.with_limit { get_page(url) }
      end
    end

  end
end
