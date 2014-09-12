class CopyAttributes
  include Interactor

  def perform
    copy_directly
    copy_and_rename
  end

  def copy_directly
    %w(
      url
      type
      description
      weight_in_pounds
      discount_in_cents
      current_price_in_cents
      price_in_cents
      sale_price_in_cents
      price_on_request
      buy_now_price_in_cents
      current_bid_in_cents
      minimum_bid_in_cents
      reserve_in_cents
      message1
      message2
      message3
      message4
      message5
    ).map(&:to_sym).each do |key|
      context[key] = listing_json[key]
    end
  end

  def copy_and_rename
    context[:availability]       = listing_json.availability || "Unknown"
    context[:item_condition]     = listing_json.condition || "Unknown"
    context[:image_source]       = listing_json.image
    context[:item_location]      = listing_json.location
    context[:upc]                = listing_json.product_upc
    context[:mpn]                = listing_json.product_mpn
    context[:sku]                = listing_json.product_sku
  end
end

