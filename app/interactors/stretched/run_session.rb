module Stretched
  class RunSession
    include Interactor
    include Stretched::PageUtils

    def perform
      #context: stretched_session

      stretched_session.urls.each do |url|
        next unless page = scrape_page(url)
        stretched_session.object_adapters.each do |adapter|
          object_q = ObjectQueue.find_or_create(adapter.queue_name)
          object_q.add ExtractJsonFromPage.perform(
            page: page,
            adapter: adapter,
            browser_session: browser_session
          )
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
