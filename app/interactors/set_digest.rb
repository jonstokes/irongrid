class SetDigest
  include Interactor

  def perform
    context[:digest] = digest
  end

  def digest
    digest_string = ""
    adapter.digest_attributes(default_digest_attributes).each do |attr|
      digest_string << "#{send(attr)}"
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
