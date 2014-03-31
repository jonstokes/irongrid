class WriteListingWorker < CoreWorker
  include ConnectionWrapper

  sidekiq_options queue: :fast_db, retry: true

  def perform(url)
    return unless ld = LinkData.find(url)
    ld.destroy
    listing = db { ld.listing_id ? Listing.find(id) : Listing.find_by_url(ld.url) }

    if listing
      existing_listing(ld, listing)
    else
      new_listing(ld)
    end
  end

  private

  def new_listing(ld)
    if ld.page_is_valid?
      return if db { Listing.find_by_digest(ld.page_attributes["digest"]) }
      klass = eval ld.page_attributes["type"]
      db { klass.create(ld.page_attributes) }
    end
  end

  def existing_listing(ld,listing)
    return if ld.page_attributes && (listing.digest == ld.page_attributes["digest"])

    if ld.page_not_found?
      db { listing.destroy }
    elsif !ld.page_is_valid?
      listing.deactivate!
    elsif Listing.duplicate_digest?(listing, ld.page_attributes["digest"])
      db { listing.destroy }
    else
      db { listing.update(ld.page_attributes) }
    end
  end
end
