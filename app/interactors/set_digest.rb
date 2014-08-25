class SetDigest
  include Interactor

  DEFAULT_DIGEST_ATTRIBUTES = %w(
    title
    keywords
    image_source
    type
    seller_domain
    item_condition
    item_location
    category1
    caliber_category
    caliber
    manufacturer
    grains
    number_of_rounds
    current_price_in_cents
  )

  def perform
    context[:digest] = digest
  end

  def digest
    digest_string = ""
    get_digest_attributes(default_digest_attributes).each do |attr|
      attribute = attr.to_sym
      next unless context[attribute]
      if context[attribute].is_a?(ElasticSearchObject)
        digest_string << "#{context[attribute].digest_string}"
      else
        digest_string << "#{context[attribute]}"
      end
    end
    Digest::MD5.hexdigest(digest_string)
  end

  def get_digest_attributes(defaults)
    return defaults unless attrs = site.digest_attributes
    return attrs unless attrs.include?("defaults")
    attrs = defaults + attrs # order matters here, so no +=
    attrs.delete("defaults")
    attrs
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
end
