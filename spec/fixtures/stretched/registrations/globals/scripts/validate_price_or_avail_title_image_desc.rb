Stretched::Script.define do
  script "globals/validate_price_or_availability_title_image_description" do
    valid do |instance|
      (instance.current_price_in_cents? || instance.price_on_request? || (instance.availability == 'in_stock')) &&
        instance.title? &&
        instance.image? &&
        instance.description?
    end
  end
end
