module Stretched
  class RunSession
    include Interactor
    include Stretched::PageUtils

    def perform
      #context: stretched_session, browser_session

      stretched_session.urls.each do |url|
        next unless page = scrape_page(url)
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
      case stretched_session.page_format.downcase
      when "dhtml"
        stretched_session.with_limit { render_page(url) }
      when "xml"
        stretched_session.with_limit { get_page(url, force_format: :xml) }
      when "html"
        stretched_session.with_limit { get_page(url, force_format: :html) }
      else
        stretched_session.with_limit { get_page(url) }
      end
    end

  end
end
