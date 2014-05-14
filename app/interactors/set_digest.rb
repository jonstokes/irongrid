class SetDigest
  include Interactor

  DEFAULT_DIGEST_ATTRIBUTES = %w(
    title
    image_source
    description
    keywords
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
    adapter.digest_attributes(default_digest_attributes).each do |attr|
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
