class PushProductLinksWorker < BaseWorker

  sidekiq_options queue: :crawls, retry: true

  track_with_schema(
    links_deleted:   Integer,
    sessions_pushed: Integer,
    transition:      String,
    next_jid:        String
  )

  before do
    @urls = Set.new
  end

  before :should_run?, :track
  after :transition, :stop_tracking

  def call
    log "Pushing #{site.link_message_queue.size} product links for #{site.domain}"
    while !timed_out? && !finished? && msg = site.link_message_queue.pop
      record_incr(:links_deleted)
      @urls << msg.url
    end
    log "Pushed a session for #{site.domain} with #{@urls.size} urls. LMQ size is #{site.link_message_queue.size}"
    record_set :sessions_pushed, site.session_queue.push(new_site_session).count
  end

  def transition
    return unless should_run?
    next_jid = self.class.perform_async(domain: site.domain)
    record_set(:transition, "#{self.class.to_s}")
    record_set(:next_jid, next_jid)
  end

  def self.should_run?(site)
    super && site.link_message_queue.any?
  end

  private

  def finished?
    @urls.size >= 300
  end

  def new_site_session
    site.new_product_session_from_urls(@urls)
  end
end
