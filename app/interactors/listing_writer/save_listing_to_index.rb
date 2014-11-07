module ListingWriter
  class SaveListingToIndex
    include Interactor

    attr_accessor :listing

    def call
      context.listing.url ||= new_url
      context.listing.id ||= listing.url

      if listing = Listing.find(context.listing.id)
        existing_listing.merge!(listing.data)
        update_existing_listing(existing_listing)
      else
        listing = context.listing
        create_new_listing
      end

    end

    def create_new_listing
      if status_valid?
        return if db { Listing.find_by_digest(listing_data.digest) }
        klass = eval listing_data[:type]
        update_geo_data(listing_data)
        db { klass.create(listing_data.to_hash) }
      end
    rescue ActiveRecord::RecordNotUnique
      notify "Listing not unique for message #{listing_data.to_hash}"
      return
    end

    def update_existing_listing(existing_listing)
      if should_destroy?(listing)
        listing.destroy
      elsif status_invalid?
        listing.deactivate!
      else
        update_geo_data
        listing.save
      end
    rescue ActiveRecord::RecordNotUnique
      notify "Listing #{listing.id} with digest #{listing.digest} and url #{listing.url} is not unique"
      return
    end

    def should_destroy?(listing)
      status_not_found? ||
          [301, 302].include?(page.code) && !status_valid? ||
          listing.duplicate_digest?(listing_data.digest)
    end

    def update_geo_data
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

    def status_valid?
      status == :success
    end

    def status_not_found?
      status == :not_found
    end

    def status
      context.status
    end


  end
end
