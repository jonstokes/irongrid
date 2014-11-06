module ListingWriter
  class SetDigest
    include Interactor

    DEFAULT_DIGEST_ATTRIBUTES = %w(
      title
      keywords
      image.source
      type
      seller.domain
      condition
      location
      product.category1
      product.caliber_category
      product.caliber
      product.manufacturer
      product.grains
      product.number_of_rounds
      price.current
    )

    def call
      context.listing.digest = digest
    end

    def digest
      digest_string = ''
      get_digest_attributes(default_digest_attributes).each do |attr|
        next unless value = instance_eval("context.listing.#{attr}")
        digest_string << "#{value}"
      end
      Digest::MD5.hexdigest(digest_string)
    end

    def get_digest_attributes(defaults)
      return defaults unless attrs = context.site.digest_attributes
      return attrs unless attrs.include?("defaults")
      attrs = defaults + attrs # order matters here, so no +=
      attrs.delete("defaults")
      attrs
    end

    def default_digest_attributes
      case context.listing.type
      when "AuctionListing"
        DEFAULT_DIGEST_ATTRIBUTES + %w(auction_ends)
      when "RetailListing"
        DEFAULT_DIGEST_ATTRIBUTES + %w(price_in_cents sale_price_in_cents price_on_request availability)
      when "ClassifiedListing"
        DEFAULT_DIGEST_ATTRIBUTES + %w(sale_price_in_cents price_in_cents)
      end
    end
  end
end
