class WriteListingWorker < CoreWorker
  include ConnectionWrapper

  sidekiq_options queue: :fast_db, retry: true

  def perform(msg)
    return unless msg = LinkMessage.new(msg)
    listing = db { msg.listing_id ? Listing.find(msg.listing_id) : Listing.find_by_url(msg.url) }

    if listing
      existing_listing(msg, listing)
    else
      new_listing(msg)
    end
  rescue ActiveRecord::RecordNotFound
    return
  end

  private

  def new_listing(msg)
    if msg.page_is_valid?
      return if db { Listing.find_by_digest(msg.page_attributes["digest"]) }
      klass = eval msg.page_attributes["type"]
      update_geo_data(msg)
      db { klass.create(msg.page_attributes) }
    end
  end

  def existing_listing(msg,listing)
    if msg.page_not_found?
      db { listing.destroy }
    elsif dirty_only?(msg, listing)
      listing.dirty!
    elsif !msg.page_is_valid?
      listing.deactivate!
    elsif Listing.duplicate_digest?(listing, msg.page_attributes["digest"])
      db { listing.destroy }
    else
      update_geo_data(msg)
      listing.update_and_dirty!(msg.page_attributes)
    end
  end

  def update_geo_data(msg)
    geo_data = lookup_geo_data(msg.page_attributes["item_data"]["item_location"])
    msg.page_attributes["item_data"].merge!(geo_data.to_h)
  end

  def lookup_geo_data(item_location)
    if item_location.present? && (loc = db { GeoData.put(item_location) })
      loc
    else
      GeoData.default_location
    end
  end

  def dirty_only?(msg, listing)
    msg.dirty_only? || (msg.page_attributes && (listing.digest == msg.page_attributes["digest"]))
  end
end
