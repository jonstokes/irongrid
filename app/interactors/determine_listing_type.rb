class DetermineListingType
  include Interactor

  def perform
    context[:type] = "#{basic_type}Listing"
  end

  def basic_type
    raw_listing['listing_type'].try(:capitalize) || adapter.default_listing_type.capitalize
  end
end
