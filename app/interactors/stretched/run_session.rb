module Stretched
  class RunSession
    include Interactor
    include Stretched::PageUtils

    def perform
      #context: stretched_session, browser_session

      stretched_session.urls.each do |url|
        next unless page = scrape_page(url)
        puts "## Page valid? #{page.is_valid?}"
        stretched_session.object_adapters.each do |adapter|
          object_q = ObjectQueue.find_or_create(adapter.queue_name)
          if page.is_valid?
            result = ExtractJsonFromPage.perform(
              page: page,
              adapter: adapter,
              browser_session: browser_session
            )
            json_objects = result.json_objects
          else
            json_objects = [{ page: page.to_hash }]
          end
          puts "## Adding #{json_objects.count} objects to queue #{object_q.name} from #{url}"
          object_q.add json_objects
        end
        context[:pages_scraped] = stretched_session.urls.count
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
