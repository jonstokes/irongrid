class ParsePagesWorker < CoreWorker
  include Sidekiq::Worker
  include PageUtils

  sidekiq_options :queue => :crawls, :retry => false

  def initialize
    @http = Anemone::HTTP.new
    @start_time = Time.now
  end

  def init(opts)
    opts.symbolize_keys!
    return false unless (@domain = opts[:domain]) && i_am_alone?(@domain)

    @site = db { Site.find_by_domain(@domain) }
    @rate_limiter = RateLimiter.new(@site.rate_limit)
    @page_queue = PageQueue.new(@domain)
    @page_queue.bypass_buffer_on_push!
    @link_store = LinkQueue.new(@domain)
    record_opts = {
      pages_created: 0,
      links_deleted: 0
    }
    track(record_opts)
    true
  end

  def perform(opts)
    return unless opts && init(opts)
    notify "Emptying link store..."
    while !timed_out? && (link = @link_store.pop) do
      record_incr(:links_deleted)
      send_to_page_queue(link)
    end
    clean_up
  end

  def clean_up
    notify "Added #{@record.pages_created} from link store."
    @page_queue.shutdown
    @link_store.shutdown
    @page_queue = @link_store = nil
    stop_tracking
  end

  def timed_out?
    Time.now - @start_time > 3.hours.to_i
  end

  def send_to_page_queue(link)
    return unless link
    return unless page = @rate_limiter.with_limit { get_page(link) }
    record_incr(:pages_created) if @page_queue.push(url: link, html: page.body)
  end
end
