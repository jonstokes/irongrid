module Stretched
  class RunSession
    include Interactor
    include Stretched::PageUtils

    def setup
      stretched_session.start!
    end

    def perform
      #context: stretched_session, browser_session

      stretched_session.urls.each do |url|
        next unless page = scrape_page(url)
        stretched_session.object_adapters.each do |adapter|
          if page.is_valid?
            result = ExtractJsonFromPage.perform(
              page: page,
              adapter: adapter,
              browser_session: browser_session
            )
            add_objects_to_queue(adapter, result.json_objects)
          else
            add_objects_to_queue(adapter, [{ page: page.to_hash }])
          end
        end
        context[:pages_scraped] = stretched_session.urls.count
      end
    ensure
      close_http_connections
    end

    private

    def add_objects_to_queue(adapter, json_objects)
      object_q = ObjectQueue.find_or_create(adapter.queue)
      results = json_objects.map do |obj|
        obj.merge(
          session: {
            key:            stretched_session.key,
            start_time:     stretched_session.start_time,
            queue_name:     stretched_session.queue_name,
            definition_key: stretched_session.definition_key
          }
        )
      end
      object_q.add results
    end

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
