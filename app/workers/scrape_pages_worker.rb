class ScrapePagesWorker < CoreWorker
  include PageUtils
  include UpdateImage
  include Trackable

  LOG_RECORD_SCHEMA = {
    db_writes:     Integer,
    links_deleted: Integer,
    pages_read:    Integer,
    images_added:  Integer,
    transition:    String,
    next_jid:      String
  }

  sidekiq_options :queue => :crawls, :retry => true

  attr_reader :domain, :site
  attr_accessor :timeout if Rails.env.test?

  def initialize
    @http = PageUtils::HTTP.new
  end

  def init(opts)
    opts.symbolize_keys!
    return false unless opts && (@domain = opts[:domain])

    @site = Site.new(domain: domain)
    @scraper = ListingScraper.new(@site)
    @rate_limiter = RateLimiter.new(@site.rate_limit)
    @timeout ||= ((60.0 / site.rate_limit.to_f) * 60).to_i
    @link_store = LinkQueue.new(domain: @site.domain)
    return false unless @link_store.any?

    @image_store = ImageQueue.new(domain: @site.domain)
    track
    true
  end

  def perform(opts)
    return unless opts && init(opts)
    notify "Emptying link store..."
    while !timed_out? && (link_data = LinkData.find(@link_store.pop)) do
      link_data.update(jid: self.jid)
      record_incr(:links_deleted)
      status_update
      @scraper.empty!
      @rate_limiter.with_limit { pull_and_process(link_data) }
    end
    clean_up
    transition
    stop_tracking
  end

  def clean_up
    notify "Added #{@record[:data][:db_writes]} from link store."
    @site.mark_read!
  end

  def transition
    if @link_store.empty? && @site.should_read?
      next_jid = RefreshLinksWorker.perform_async(domain: domain)
      record_set(:transition, "RefreshLinksWorker")
      record_set(:next_jid, next_jid)
    elsif @link_store.any?
      next_jid = self.class.perform_async(domain: domain)
      record_set(:transition, "#{self.class.to_s}")
      record_set(:next_jid, next_jid)
    end
  end

  #
  # private
  #

  def timed_out?
    (@timeout -= 1).zero?
  end

  def pull_and_process(link_data)
    url = link_data.url
    if page = get_page(url)
      record_incr(:pages_read)
      @scraper.parse(doc: page.doc, url: url)
      if listing_is_unchanged?(link_data)
        link_data.update(dirty_only: true)
      else
        update_image if @scraper.is_valid?
        link_data.update(
          page_is_valid:   @scraper.is_valid?,
          page_not_found:  @scraper.not_found?,
          page_attributes: @scraper.listing
        )
      end
    else
      link_data.update(page_not_found: true)
    end
    WriteListingWorker.perform_async(url)
    record_incr(:db_writes)
  end

  def listing_is_unchanged?(link_data)
    link_data.listing_digest && (@scraper.listing["digest"] == link_data.listing_digest)
  end
end
