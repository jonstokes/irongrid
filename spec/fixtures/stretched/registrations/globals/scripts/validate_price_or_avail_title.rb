Stretched::Script.define do
  script "globals/validate_price_or_availability_title" do
    valid do |instance|
      (instance.current_price_in_cents? || instance.price_on_request? || (instance.availability == 'in_stock')) &&
        instance.title?
    end
  end
end
