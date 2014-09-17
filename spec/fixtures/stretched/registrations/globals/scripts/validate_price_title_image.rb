Stretched::Script.define do
  script "globals/validate_price_title_image" do
    valid do |instance|
      (instance.current_price_in_cents? || instance.price_on_request?) &&
        instance.title? &&
        instance.image?
    end
  end
end
