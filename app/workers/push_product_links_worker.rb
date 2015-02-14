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

  before :testing, :should_run?, :track
  after :transition, :stop_tracking

  def testing
    ring "Should run? #{should_run?}: #{site.link_message_queue.any?}"
  end

  def call
    ring "Called with site #{site.domain}, LMQ size is #{site.link_message_queue.size}"
    while !timed_out? && !finished? && msg = site.link_message_queue.pop
      record_incr(:links_deleted)
      @urls << msg.url
    end

    record_set :sessions_pushed, site.session_queue.push(new_session).count
    ring "# Finished #{site.domain}'s LMQ. Final LMQ size is #{site.link_message_queue.size}."
  end

  def transition
    ring "Should transition? #{should_run?}: #{site.link_message_queue.any?}"
    return unless should_run?
    next_jid = self.class.perform_async(domain: site.domain)
    ring "Transitioned to #{next_jid}"
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

  def new_session
    return unless @urls.try(:any?)
    site.product_session_format.merge('urls' => url_list)
  end

  def url_list
    @urls.to_a.map { |url| { url: url } }
  end

end
