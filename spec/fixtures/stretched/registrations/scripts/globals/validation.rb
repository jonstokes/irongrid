Stretched::Script.define do
  script "globals/validation" do
    valid do |instance|
      (instance.current_price_in_cents? || instance.price_on_request? || instance.availability?) &&
        instance.title? &&
        instance.image?
    end
  end
end
