module Stretched
  class RunSessionsWorker
    include Stretched::PageUtils

    sidekiq_options :queue => :crawls, :retry => true

    attr_accessor :timeout if Rails.env.test?

    def init(opts)
      opts.symbolize_keys!
      return false unless i_am_alone_with_this_domain? || (@debug = opts[:debug])

      @timer = Stretched::RateLimiter.new(opts[:timeout] || 1.hour.to_i)
      @session_q = SessionQueue.new(opts[:session_queue_name])
      @object_q = ObjectQueue.new(a
      return false unless @session_q.any?

      true
    end

    def perform(opts)
      return unless opts && init(opts)
      notify "Emptying session queue for #{session_q.key}..."
      while !timer.timed_out? && (ssn = @session_q.pop) do
        outlog "Popped session with definition #{ssn.session_definition.key}"
        objects = RunSession.perform(stretched_session: ssn, browser_session: browser_session)
        object_q.add(objects)
        outlog "Session #{ssn.key} finished! Timeout is #{@timeout}"
      end
      clean_up
      transition
    ensure
      close_http_connections
    end

    def clean_up
      # Log out the end of the session
    end

    def transition
      if @session_q.any?
        self.class.perform_async(domain: domain)
      end
    end

    def outlog(str)
      return unless @debug
      notify "### #{str}"
    end

    private

    def browser_session
      return unless @dhttp
      @dhttp.session
    end

    def pull_and_process(msg)
      if @site.page_adapter && scraper = scrape_page(msg.url)
        outlog "Url scraped!"
        if listing_is_unchanged?(msg, scraper)
          outlog "Updating unchanged message"
          update_image(scraper)
          msg.update(
            dirty_only:    true,
            page_is_valid: scraper.is_valid?
          )
        else
          outlog "Updating new message"
          update_image(scraper) if scraper.is_valid?
          msg.update(
            page_is_valid:        scraper.is_valid?,
            page_not_found:       scraper.not_found?,
            page_classified_sold: scraper.classified_sold?,
            page_attributes:      scraper.listing
          )
        end
      else
        outlog "Updating not_found message"
        msg.update(page_not_found: true)
      end
      outlog "Writing listing for #{msg.url}"
      WriteListingWorker.perform_async(msg.to_h)
      record_incr(:db_writes)
    end

    def scrape_page(url)
      outlog "Fetching #{url}"
      return unless page = @rate_limiter.with_limit { fetch_page(url) }
      outlog "Url fetched!"
      record_incr(:pages_read)
      outlog "Parsing page for #{url}"
      ParsePage.perform(
        site: @site,
        page: page,
        url: url,
        adapter_type: :page
      )
    end

    def fetch_page(url)
      if site.page_adapter['format'] == "dhtml"
        render_page(url)
      else
        get_page(url)
      end
    end

    def listing_is_unchanged?(msg, scraper)
      msg.listing_digest && (scraper.listing.try(:[], 'digest') == msg.listing_digest)
    end
  end
end
