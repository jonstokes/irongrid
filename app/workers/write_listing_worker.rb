class WriteListingWorker < CoreWorker
  include ConnectionWrapper

  sidekiq_options queue: :db_fast_high, retry: true

  def perform(msg)
    return unless msg = LinkMessage.new(msg)

    if listing ||= db { Listing.find_by_url(msg.url) }
      existing_listing(msg, listing)
    else
      new_listing(msg)
    end
  end

  private

  def new_listing(msg)
    if msg.page_is_valid?
      return if db { Listing.find_by_digest(msg.page_attributes["digest"]) }
      klass = eval msg.page_attributes["type"]
      update_geo_data(msg)
      db { klass.create(msg.page_attributes) }
    end
  rescue ActiveRecord::RecordNotUnique
    notify "Listing not unique for message #{msg.to_h}", type: :error
    return
  end

  def existing_listing(msg, listing)
    if msg.page_not_found?
      db { listing.destroy }
    elsif !msg.page_is_valid?
      listing.deactivate!
    elsif dirty_only?(msg, listing)
      listing.dirty_only!
    elsif Listing.duplicate_digest?(listing, msg.page_attributes["digest"])
      db { listing.destroy }
    else
      update_geo_data(msg)
      listing.update_with_count(msg.page_attributes)
    end
  rescue ActiveRecord::RecordNotUnique
    notify "Listing #{listing.id} with digest #{listing.digest} and url #{listing.url} is not unique, msg is #{msg.to_h}", type: :error
    return
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
    msg.page_attributes && (listing.digest == msg.page_attributes["digest"])
  end
end
