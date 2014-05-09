class SetAvailability
  include Interactor

  def perform
    context[:item_data]['availability'] = stock_status.parameterize("_")
  end

  def stock_status
    if type == "RetailListing"
      retail_stock_status
    else
      "In Stock"
    end
  end

  def retail_stock_status
    #FIXME: Convert all this stock_status stuff to availability at some point.
    # This will ruin all the digests, though.
    if ["In Stock", "Out Of Stock"].include? raw_listing['stock_status']
      raw_listing['stock_status']
    else
      adapter.default_stock_status.try(:titleize) || "N/A"
    end
  end
end
