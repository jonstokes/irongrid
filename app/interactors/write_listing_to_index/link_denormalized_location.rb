class WriteListingToIndex
  class LinkDenormalizedLocation
    include Interactor

    # TODO: Split this into two interactors, FindOrCreateLocation and LinkDenormalizedLocation

    def call
      listing.location ||= {}
      return if listing.location.coordinates
      geo_data = lookup_geo_data(context.listing_json.location)
      listing.location = IronBase::DenormalizeLocationForListing.call(location: geo_data).denormalized_location
    end

    def lookup_geo_data(item_location)
      if item_location.present? && (loc = IronBase::Location.put(item_location))
        loc
      else
        IronBase::Location.default_location
      end
    end

    def listing
      context.listing
    end

  end
end