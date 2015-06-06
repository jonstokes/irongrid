class PullProductLinksWorker < BaseWorker
  sidekiq_options queue: :crawls, retry: true

  track_with_schema(
    objects_deleted: Integer,
    links_created:   Integer
  )

  before :should_run?, :track
  after :stop_tracking

  def call
    log "Pulling product links for #{site.domain} with queue size #{site.product_links_queue.size}"
    while !timed_out? && obj = site.product_links_queue.pop
      record_incr(:objects_deleted)
      next unless obj.object.try(:product_link)
      record_incr(:links_created) unless push_link(obj.object.product_link).zero?
    end
    log "Pulled #{record[:data][:links_created]} product links for #{site.domain}. Queue size is #{site.product_links_queue.size}"
  end

  def push_link(link)
    site.link_message_queue.push IronCore::LinkMessage.new(url: link)
  end

  def self.should_run?(site)
    super && site.product_links_queue.any?
  end
end
