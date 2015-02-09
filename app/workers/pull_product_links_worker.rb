class PullProductLinksWorker < BaseWorker
  sidekiq_options queue: :crawls, retry: true

  track_with_schema(
    objects_deleted: Integer,
    links_created:   Integer,
    transition:      String,
    next_jid:        String
  )

  before :track
  after :stop_tracking

  def call(opts)
    while !timed_out? && obj = site.product_links_queue.pop
      record_incr(:objects_deleted)
      next unless obj.object && obj.object.product_link
      record_incr(:links_created)
      site.link_message_queue.push IronCore::LinkMessage.new(url: obj.object.product_link)
    end
  end

  def self.should_run?(site)
    site.product_links_queue.any?
  end
end
