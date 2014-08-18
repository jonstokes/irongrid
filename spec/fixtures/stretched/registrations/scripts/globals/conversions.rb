Stretched::Script.define do
  script "globals/conversions" do

    price_in_cents do |instance|
      convert_dollars_to_cents(instance.price_in_cents)
    end

    sale_price_in_cents do |instance|
      convert_dollars_to_cents(instance.sale_price_in_cents)
    end

  end
end

