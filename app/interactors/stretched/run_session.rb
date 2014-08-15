module Stretched
  class RunSession
    include Interactor
    include Stretched::PageUtils

    def perform
      #context: stretched_session, browser_session

      stretched_session.urls.each do |url|
        puts "##### Scraping #{url}"
        next unless page = scrape_page(url)
        puts "## Got page for #{url}"
        stretched_session.object_adapters.each do |adapter|
          object_q = ObjectQueue.find_or_create(adapter.queue_name)
          puts "## Exracting JSON from #{page.url} with #{adapter.key} for queue #{adapter.queue_name}"
          result = ExtractJsonFromPage.perform(
            page: page,
            adapter: adapter,
            browser_session: browser_session
          )
          puts "## Got #{result.json_objects.count} objects from #{url}"
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
