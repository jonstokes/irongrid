class UpdateListingFromProduct
  include Interactor

  before do
    listing.product ||= {}
  end

  def call
    # Use assignments so that dirty flag is set when appropriate
    return unless listing.present? && product.present?

    product_attributes = IronBase::Listing.mapping.listing.properties.product.properties.keys

    product.to_hash.slice(*product_attributes).each do |k, v|
      if should_lowercase?(k) && !listing.product[k].present?
        listing.product[k] = v.downcase
      else
        listing.product[k] = v
      end
    end
  end

  def product
    context[:product]
  end

  def listing
    context[:listing]
  end

  def self.schema
    @schema ||= Stretched::Schema.find("Listing")
  end

  def should_lowercase?(key)
    lowercased_properties.include?(key)
  end

  def lowercased_properties
    @lowercased_properties ||= self.class.schema.data['properties'].select do |k, v|
      v['enum'] && v['enum'] == v['enum'].map(&:downcase)
    end.keys.map { |k| k.split('product_').last }
  end
end
