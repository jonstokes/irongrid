module Stretched
  class RunSession
    include Interactor

    def perform
      #context: stretched_session, browser_session
      rate_limiter = Stretched::RateLimiter.new(stretched_session.rate_limit)

      stretched_session.urls.each do |url|
        page = fetch_page(url)
        stretched_session.object_adapters.each do |adapter|
          objects = ExtractJsonFromPage(page: page, adapter: adapter)
        end
      end
    end

  end
end
