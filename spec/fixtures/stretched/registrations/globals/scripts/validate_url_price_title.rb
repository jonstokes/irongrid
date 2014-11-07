Stretched::Script.define do
  script "globals/validate_url_price_title" do
    valid do |instance|
      (instance.current_price_in_cents? || instance.price_on_request?) &&
        instance.title? && instance.url?
    end
  end
end
