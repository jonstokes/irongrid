Stretched::Script.define do
  script "globals/product_page" do

    availability do |instance|
      if %w(AuctionListing ClassifiedListing).include?(instance.type)
        "in_stock"
      else
        instance.availability
      end
    end

    image do |instance|
      if instance.image?
        clean_up_image_url(instance.image)
      end
    end

    price_in_cents do |instance|
      convert_dollars_to_cents(instance.price_in_cents)
    end

    sale_price_in_cents do |instance|
      convert_dollars_to_cents(instance.sale_price_in_cents)
    end

    buy_now_price_in_cents do |instance|
      convert_dollars_to_cents(instance.buy_now_price_in_cents)
    end

    current_bid_in_cents do |instance|
      convert_dollars_to_cents(instance.current_bid_in_cents)
    end

    minimum_bid_in_cents do |instance|
      convert_dollars_to_cents(instance.minimum_bid_in_cents)
    end

    reserve_in_cents do |instance|
      convert_dollars_to_cents(instance.reserve_in_cents)
    end

    current_price_in_cents do |instance|
      case instance.type
      when "AuctionListing"
        [
          instance.buy_now_price_in_cents,
          instance.current_bid_in_cents,
          instance.minimum_bid_in_cents,
          instance.reserve_in_cents
        ].compact.sort.last
      when "RetailListing"
        instance.sale_price_in_cents || instance.price_in_cents
      when "ClassifiedListing"
        instance.price_in_cents
      end
    end

    product_number_of_rounds do |instance|
      instance.number_of_rounds.delete(",").to_i if instance.number_of_rounds?
    end

    product_grains do |instance|
      if instance.grains?
        g = instance.grains.delete(",").to_i
        (g > 0 && g < 400) ? g : nil
      end
    end

    price_per_round_in_cents do |instance|
      if (instance.category1 == "Ammunition") && instance.current_price_in_cents? && instance.number_of_rounds?
        (instance.current_price_in_cents.to_f / instance.number_of_rounds.raw.to_f).round rescue 0
      end
    end
  end
end

