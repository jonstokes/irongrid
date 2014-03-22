class ScrapePagesWorker < CoreWorker
  include PageUtils

  attr_reader :domain, :site

  sidekiq_options :queue => :crawls, :retry => false

  def initialize
    @http = PageUtils::HTTP.new
  end

  def init(opts)
    return false unless opts
    opts.symbolize_keys!
    return false unless @domain = opts[:domain]

    @site = Site.new(domain: domain, source: :redis)
    @scraper = ListingScraper.new(@site)
    @rate_limiter = RateLimiter.new(@site.rate_limit)
    @timeout ||= ((60.0 / site.rate_limit.to_f) * 60).to_i
    @link_store = LinkStore.new(domain: domain)
    record_opts = {
      pages_created: 0,
      links_deleted: 0
    }
    track(record_opts)
    true
  end

  def perform(opts)
    return unless init(opts)

    notify "Emptying link store..."
    while !timed_out? && ((link = @link_store.pop) || ReadListingLinkWorker.jobs_in_flight_for_domain(domain).any?) do
      record_incr(:links_deleted)
      @rate_limiter.with_limit { pull_and_process(link) }
    end
    clean_up
    transition
  end

  def clean_up
    notify "Added #{@record.pages_created} from link store."
    stop_tracking
  end

  def transition
    if @link_store.empty? && @image_store.empty?
      RefreshLinksWorker.perform_async(domain: domain)
    elsif !@link_store.empty?
      self.class.perform_async(domain: domain)
    end
  end

  #
  # private
  #

  def timed_out?
    (@timeout -= 1).zero?
  end

  def pull_and_process(url)
    page = get_page(url)
    if page[:id]
      process_existing_listing(url: url, page: page)
    else
      process_possible_new_listing(url: url, page: page)
    end
    @scraper.empty!
  end

  def process_possible_new_listing(opts)
    page, url = opts[:page], opts[:url]
    return if page.nil?
    scraper.parse(doc: page.doc, url: url)
    return if page_is_a_duplicate?(scraper, page)
    update_image(scraper)
    WriteListingWorker.perform_async(attributes: scraper.listing, action: :create)
  end

  def process_existing_listing(opts)
    listing, url, page = opts[:listing], opts[:url], opts[:page]
    return WriteListingWorker.perform_async(id: listing.id, action: :delete) if page.nil?
    scraper.parse(doc: page.doc, url: url)
    if scraper.is_valid?
      if page_is_a_duplicate(scraper, listing)
        #FIXME: Can't do this. See below
        WriteListingWorker.perform_async(id: listing.id, action: :delete)
      else
        update_image(scraper)
        WriteListingWorker.perform_async(id: listing.id, attributes: scraper.listing, action: :update)
      end
    else
      WriteListingWorker.perform_async(id: listing.id, action: :deactivate)
    end
  end

  def update_image(scraper)
    if image = CDN.url_for_image(scraper.listing["image_source_url"])
      scraper.listing["image"] == image
    else
      image_set = ImageSet.new(domain: listing.seller_domain)
      image_set.add scraper.listing["image_source_url"]
    end
  end

  def page_is_a_duplicate?(scraper, listing=nil)
    #FIXME: Can't do this now!. Will have to enqueue it via WLW & let WLW discard it later.
    if listing
      !!Listing.find("id != ? AND digest = ?", listing.id, scraper.listing["digest"])
    else
      !!Listing.find_by_digest(scraper.listing["digest"])
    end
  end
end
