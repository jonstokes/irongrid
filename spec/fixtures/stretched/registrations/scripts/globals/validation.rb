Stretched::Script.define do
  script "globals/validation" do
    valid do |instance|
      puts "## Validating #{instance.inspect}"
      (instance.current_price_in_cents? || instance.price_on_request?) &&
        instance.title? &&
        instance.image? &&
        instance.availability?
    end
  end
end
