Stretched::Script.define do
  script "globals/validate_price_or_availability_title_description" do
    valid do |instance|
      (instance.current_price_in_cents? || instance.price_on_request? || instance.availability?) &&
        instance.title? &&
        instance.description?
    end
  end
end
