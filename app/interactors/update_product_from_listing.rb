class UpdateProductFromListing
  include Interactor

  def call
    # Use assignments so that dirty flag is set when appropriate
    return unless listing.product_source.present? && product.present?

    listing.product_source.each do |k, v|
      next if %w(weight mpn upc sku).include?(k)
      product.send("#{k}=", v)
    end

    product.name        = listing.title
    product.engine      = listing.engine
    product.msrp        = msrp
    product.weight      = weight
    product.description = description
    product.image       = image
    product.upc         = listing.product_source.try(:upc)
    product.mpn         = listing.product_source.try(:mpn)
    product.sku         = listing.product_source.try(:sku)

    product.normalize!
  end

  def msrp
    listing.price.list
  rescue
    product.msrp
  end

  def description
    return product.description unless listing.description
    { long: listing.description }
  end

  def image
    if listing.image.try(:cdn) || product.image.nil?
      listing.image
    else
      product.image
    end
  end

  def weight
    return product.weight unless listing.product_source.try(:weight)
    { shipping: listing.product_source.weight }
  end

  def product
    context[:product]
  end

  def listing
    context[:listing]
  end
end
