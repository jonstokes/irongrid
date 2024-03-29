class PullListingsWorker < BaseWorker

  sidekiq_options :queue => :crawls, :retry => true

  track_with_schema(
    listings_created: Integer,
    listings_deleted: Integer,
    objects_deleted:  Integer,
    images_added:     Integer,
    transition:       String,
    next_jid:         String
  )

  before :should_run?, :track
  after :transition, :stop_tracking

  def call
    log "Pulling listings for #{site.domain} with queue size #{site.listings_queue.size}"
    while !timed_out? && json = site.listings_queue.pop do
      record_incr(:objects_deleted)
      if (page_not_found?(json) || listing_json_not_found?(json)) && !site.full_feed
        destroy_listings_at_url(json)
        next
      end
      record_incr(:listings_created) if parse(json)
    end
    log "Pulled #{record[:data][:objects_deleted]} listings for #{site.domain}. Queue size is #{site.listings_queue.size}"
  end

  def transition
    return if site.listings_queue.empty?
    next_jid = self.class.perform_async(domain: site.domain)
    record_set(:transition, "#{self.class.to_s}")
    record_set(:next_jid, next_jid)
  end

  def should_run?
    self.class.should_run?(site) || abort!
  end

  def self.should_run?(site)
    super && site.listings_queue.any? && self.new_jobs_allowed?(site)
  end

  def self.new_jobs_allowed?(site)
    jobs_in_flight = self.jobs_in_flight_with_domain(site.domain).size
    total_jobs_allowed = site.listings_queue.size / 100
    total_jobs_allowed = total_jobs_allowed.zero? ? 1 : total_jobs_allowed
    jobs_in_flight < total_jobs_allowed
  end

  private

  def destroy_listings_at_url(json)
    # TODO: Improve this with the bulk listings API
    possible_index_urls(json).each do |url|
      next unless listings = Retryable.retryable { IronBase::Listing.find_by_url(url) }
      listings.each do |listing|
        record_incr(:listings_deleted)
        Retryable.retryable { listing.destroy }
      end
    end
  end

  def possible_index_urls(json)
    redirect = URI.unescape(json.page.redirect_from) rescue nil
    page = URI.unescape(json.page.url) rescue nil
    [json.page.redirect_from, redirect, json.page.url, page].compact.uniq
  end

  def listing_json_not_found?(json)
    json.object.nil? || json.object.not_found
  end

  def page_not_found?(json)
    !json.page.fetched? ||
        json.page.error ||
        !json.page.body? ||
        json.page.code.nil? ||
        (json.page.code.to_i == 404)
  end

  def parse(json)
    if json.error?
      error "Stretched error on page #{json.page.url}\n#{json.error}"; nil
    else
      result = WriteListingToIndex.call(
          site:         site,
          listing_json: json.object,
          page:         json.page
      )
      result.success?
    end
  end
end
