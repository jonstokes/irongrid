class WriteListingWorker < CoreWorker
  include ConnectionWrapper

  sidekiq_options queue: :db_fast_high, retry: true

  attr_reader :listing_data, :page, :status


  def init(opts)
    return unless opts
    opts.symbolize_keys!
    @listing_data = Hashie::Mash.new(opts[:listing])
    @page = Hashie::Mash.new(opts[:page])
    @status = opts[:status].try(:to_sym)
    true
  end

  def perform(opts)
    return unless init(opts)

    url = @listing_data.url || @page.redirect_from || @page.url
    if listing ||= db { Listing.find_by_url(url) }
      update_existing_listing
    else
      create_new_listing
    end
  end

  private

  def new_listing
    if listing_data.valid?
      return if db { Listing.find_by_digest(listing_data.digest) }
      klass = eval listing_data[:type]
      update_geo_data(listing_data)
      listing_data.url ||= new_url
      db { klass.create(listing_data.to_hash) }
    end
  rescue ActiveRecord::RecordNotUnique
    notify "Listing not unique for message #{listing.to_hash}", type: :error
    return
  end

  def existing_listing(listing)
    if status_not_found?
      db { listing.destroy }
    elsif status_invalid?
      listing.deactivate!
    elsif dirty_only?(listing_data, listing)
      listing.dirty_only!
    elsif Listing.duplicate_digest?(listing, listing_data.digest)
      db { listing.destroy }
    else
      listing_data.url ||= new_url
      update_geo_data(listing_data)
      listing.update_with_count(listing_data.to_hash)
    end
  rescue ActiveRecord::RecordNotUnique
    notify "Listing #{listing.id} with digest #{listing.digest} and url #{listing.url} is not unique, msg is #{msg.to_h}", type: :error
    return
  end

  def new_url
    (page.code == 301) ? page.url : page.redirect_from
  end

  def update_geo_data(listing_data)
    geo_data = lookup_geo_data(listing_data.item_data.item_location)
    listing_data.item_data.merge!(geo_data.to_h)
  end

  def lookup_geo_data(item_location)
    if item_location.present? && (loc = db { GeoData.put(item_location) })
      loc
    else
      GeoData.default_location
    end
  end

  def status_invalid?
    status == :invalid
  end

  def status_not_found?
    status == :not_found
  end

  def dirty_only?(listing_data, listing)
    listing_data && (listing.digest == listing_data.digest)
  end
end
