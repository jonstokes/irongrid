Stretched::Script.define do
  script "globals/validate_id_price_title" do
    valid do |instance|
      (instance.current_price_in_cents? || instance.price_on_request?) &&
        instance.title? && instance.id?
    end
  end
end
