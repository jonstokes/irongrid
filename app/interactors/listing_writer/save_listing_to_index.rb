module ListingWriter
  class SaveListingToIndex
    include Interactor

    def listing
      context.listing
    end

    def status
      context.status
    end

    def call
      if listing.persisted?
        update_existing_listing
      elsif status_valid? && !Listing.find_by_digest(listing.digest)
        update_geo_data
        listing.save
      end
    end

    def update_existing_listing
      if should_destroy?
        listing.destroy
      elsif status_invalid?
        listing.deactivate!
      else
        update_geo_data
        listing.save
      end
    end

    def should_destroy?
      status_not_found? ||
          redirected? && status_invalid? ||
          listing.digest_would_be_duplicate?
    end

    def update_geo_data
      return if listing.location.coordinates
      geo_data = lookup_geo_data(listing.location.source)
      listing.location.merge!(geo_data.to_h)
    end

    def lookup_geo_data(item_location)
      if item_location.present? && (loc = Location.put(item_location))
        loc
      else
        Location.default_location
      end
    end

    def redirected?
      [301, 302].include?(context.page.code)
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
  end
end
