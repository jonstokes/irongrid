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

  before :track
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
    site.link_message_queue.any?
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
