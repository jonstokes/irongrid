class ScrapePageWorker < BaseWorker
  sidekiq_options queue: :scrapes, retry: false

  attr_reader :site

  def user
    @user ||= context[:user]
  end

  def session
    @session ||= YAML.load(context[:session]) rescue nil
  end

  before do
    @site = IronCore::Site.find(domain, source: :validator_redis_pool)
    @site.user = user
  end

  def call
    populate_session_queue
    results = pull_results
    IronCore::ValidatorQueue.add(jid, results)
  rescue Exception => e
    results.merge!(error: "#{e.inspect}. #{e.backtrace}")
    IronCore::ValidatorQueue.add(jid, results)
  end

  def should_run?
    user && session && site
  end

  private

  def populate_session_queue
    site.session_queue.push session
    sleep 1 while site.session_queue_active?
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