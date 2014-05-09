class CleanUpTypeDependentAttributes
  include Interactor

  def perform
    context[:digest] = digest
    context[:item_data]['availability'] = availability
    context[:item_data]['digest'] = digest
  end

  def digest
    digest_string = ""
    adapter.digest_attributes(default_digest_attributes).each do |attr|
      if ES_OBJECTS.include?(attr)
        digest_string << "#{es_objects[attr.to_sym]}"
      elsif send(attr)
        digest_string << "#{send(attr)}"
      end
    end
    Digest::MD5.hexdigest(digest_string)
  end

  def default_digest_attributes
    case type
    when "AuctionListing"
      DEFAULT_DIGEST_ATTRIBUTES + %w(auction_ends)
    when "RetailListing"
      DEFAULT_DIGEST_ATTRIBUTES + %w(price_in_cents sale_price_in_cents price_on_request stock_status)
    when "ClassifiedListing"
      DEFAULT_DIGEST_ATTRIBUTES + %w(sale_price_in_cents price_in_cents)
    end
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
