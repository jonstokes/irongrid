class ScrapePageWorker < Bellbro::Worker
  include Sunbro

  sidekiq_options :queue => :scrapes, :retry => false

  attr_reader :domain, :site, :session, :domain, :user

  def init(opts)
    opts.symbolize_keys!
    return false unless @domain = opts[:domain]
    return false unless @user = opts[:user]
    return false unless session_source = opts[:session]
    @session = YAML.load(session_source)
    @site = IronCore::Site.new(
        domain: @domain,
        user:   @user,
    )
    true
  end

  def perform(opts)
    results = {}
    return unless opts && init(opts)
    populate_session_queue
    results = pull_results
    IronCore::ValidatorQueue.add(jid, results)
  rescue Exception => e
    results.merge!(error: "#{e.inspect}. #{e.backtrace}")
    IronCore::ValidatorQueue.add(jid, results)
    results
  ensure
    close_http_connections
  end

  private

  def populate_session_queue
    site.session_queue.push session
    sleep 1 while site.session_queue.is_being_read?
  end

  def pull_results
    product_links = []
    listings = []
    while obj = site.product_links_queue.pop
      product_links << obj
    end
    while obj = site.listings_queue.pop
      listings << obj
    end
    { product_links: product_links, listings: listings }
  end

end