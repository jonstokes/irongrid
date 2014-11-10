class SetListingLocation
  include Interactor

  def call
    listing.location ||= {}
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

  def listing
    context.listing
  end

end