class WriteListingWorker < CoreWorker
  include ConnectionWrapper

  sidekiq_options queue: :fast_db, retry: true

  def perform(url)
    return unless ld = LinkData.find(url)
    ld.destroy
    listing = db { ld.listing_id ? Listing.find(ld.listing_id) : Listing.find_by_url(ld.url) }

    if listing
      existing_listing(ld, listing)
    else
      new_listing(ld)
    end
  rescue ActiveRecord::RecordNotFound
    return
  end

  private

  def new_listing(ld)
    if ld.page_is_valid?
      return if db { Listing.find_by_digest(ld.page_attributes["digest"]) }
      klass = eval ld.page_attributes["type"]
      update_geo_data(ld)
      db { klass.create(ld.page_attributes) }
    end
  end

  def existing_listing(ld,listing)
    if ld.page_not_found?
      db { listing.destroy }
    elsif dirty_only?(ld, listing)
      listing.dirty!
    elsif !ld.page_is_valid?
      listing.deactivate!
    elsif Listing.duplicate_digest?(listing, ld.page_attributes["digest"])
      db { listing.destroy }
    else
      update_geo_data(ld)
      listing.item_data_will_change!
      listing.dirty
      db { listing.update(ld.page_attributes) }
    end
  end

  def update_geo_data(ld)
    geo_data = lookup_geo_data(ld.page_attributes["item_data"]["item_location"])
    ld.page_attributes["item_data"].merge!(geo_data.to_h)
  end

  def lookup_geo_data(item_location)
    if item_location.present? && (loc = db { GeoData.put(item_location) })
      loc
    else
      GeoData.default_location
    end
  end

  def dirty_only?(ld, listing)
    ld.dirty_only? || (ld.page_attributes && (listing.digest == ld.page_attributes["digest"]))
  end
end
