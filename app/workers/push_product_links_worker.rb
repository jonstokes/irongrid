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
    while !timed_out? && !finished? && msg = site.link_message_queue.pop
      record_incr(:links_deleted)
      @urls << msg.url
    end

    record_set :sessions_pushed, site.session_queue.push(new_session).count
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

  def self.prune_refresh_push_cycle_is_running?(domain)
    PruneLinksWorker.jobs_in_flight_with_domain(domain).any? ||
        RefreshLinksWorker.jobs_in_flight_with_domain(domain).any?
  end


  private

  def finished?
    @urls.size >= 300
  end

  def new_session
    return unless @urls.try(:any?)
    site.product_session_format.merge('urls' => url_list)
  end

  def url_list
    @urls.to_a.map { |url| { url: url } }
  end

end
