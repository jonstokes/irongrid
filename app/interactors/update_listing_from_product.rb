class UpdateListingFromProduct
  include Interactor

  before do
    listing.product = {}
  end

  def call
    # Use assignments so that dirty flag is set when appropriate
    return unless listing.present? && product.present?

    product.engine ||= listing.engine

    product_data.each do |k, v|
      if permitted_product_data.include?(k)
        listing.product[k] = get_product_value(k, v)
      else
        listing.product[k] = nil
      end
    end
  end

  def permitted_product_data
    product_data.slice(*product.allowed_fields).keys + %w(id)
  end

  def product_data
    product.to_hash.slice(*product_attributes)
  end

  def product_attributes
    IronBase::Listing.mapping.listing.properties.product.properties.keys
  end

  def get_product_value(attr, value)
    if listing.product_source[attr].present?
      product.normalized_for attr, listing.product_source[attr]
    elsif attr == 'number_of_rounds'
      # Only pull num rounds from the product if there's a UPC match
      value if context.match_type == :upc
    else
      value
    end
  end

  def product
    context[:product]
  end

  def listing
    context[:listing]
  end
end
