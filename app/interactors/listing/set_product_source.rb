class SetProductSource
  include Interactor

  def call
    context.listing.product_source = {}
    context.listing_json.each do |field, value|
      if field.to_s[/product_/]
        context.listing.product_source.merge!("#{field.split("product_").last}" => value)
      elsif field.to_s == 'weight_in_pounds'
        context.listing.product_source.merge!('weight' => value)
      end
    end

  end
end