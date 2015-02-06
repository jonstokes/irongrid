class PullListingsWorker < Bellbro::Worker

  sidekiq_options :queue => :crawls, :retry => true

  track_with_schema(
    listings_created: Integer,
    listings_deleted: Integer,
    objects_deleted:  Integer,
    images_added:     Integer,
    transition:       String,
    next_jid:         String
  )

  attr_accessor :domain, :timer, :site
  delegate :timed_out?, to: :timer

  def init(opts)
    opts.symbolize_keys!
    return false unless opts && @domain = opts[:domain]
    @site = IronCore::Site.new(domain: @domain)
    @timer = RateLimiter.new(opts[:timeout] || 1.hour.to_i)
    @object_queue = Stretched::ObjectQueue.new("#{site.domain}/listings")
    @image_store = IronCore::ImageQueue.new(domain: site.domain)
    return false unless @object_queue.any?
    track
    true
  end

  def perform(opts)
    return unless opts && init(opts)

    while !timed_out? && json = @object_queue.pop do
      record_incr(:objects_deleted)
      if page_not_found?(json) || listing_json_not_found?(json)
        destroy_listings_at_url(json)
        next
      end
      record_incr(:listings_created) if parse(json)
    end

    transition
    stop_tracking
  end

  def destroy_listings_at_url(json)
    # TODO: Improve this with the bulk listings API
    possible_index_urls(json).each do |url|
      next unless listings = retryable { IronBase::Listing.find_by_url(url) }
      listings.each do |listing|
        record_incr(:listings_deleted)
        retryable { listing.destroy }
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
      ring "# STRETCHED ERROR on page #{json.page.url}\n#{json.error}"; nil
    else
      result = WriteListingToIndex.call(
          site:         site,
          listing_json: json.object,
          page:         json.page
      )
      result.success?
    end
  end

  def transition
    if @object_queue.any?
      next_jid = self.class.perform_async(domain: site.domain)
      record_set(:transition, "#{self.class.to_s}")
      record_set(:next_jid, next_jid)
    end
  end

end
