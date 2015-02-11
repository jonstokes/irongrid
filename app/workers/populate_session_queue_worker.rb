class PopulateSessionQueueWorker < BaseWorker

  sidekiq_options :queue => :crawls, :retry => true
  track_with_schema(
    sessions_added:  Integer,
  )

  before :should_run?, :track
  after { site.mark_read! }
  after :stop_tracking

  def call
    site.session_queue.add(site.sessions)
    record_set :sessions_added, site.sessions.count
  end

  def self.should_run?(site)
    site.should_read? &&
      site.session_queue_inactive? &&
      site.product_links_queue.empty? &&
      site.link_message_queue.empty? &&
      !prune_refresh_push_cycle_is_running?(site.domain)
  end

end
