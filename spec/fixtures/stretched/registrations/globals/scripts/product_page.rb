Stretched::Script.define do
  script "globals/product_page" do
    url do |instance|
      clean_up_url(instance.url)
    end

    availability do |instance|
      if %w(AuctionListing ClassifiedListing).include?(instance['type'])
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
      case instance['type']
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
      if numrounds = instance.product_number_of_rounds
        r = numrounds.is_a?(String) ? numrounds.delete(",").to_i : numrounds
      else
        r = extract_number_of_rounds(instance.title).try(:to_i) ||
          extract_number_of_rounds(instance.keywords).try(:to_i)
      end
      restrict_to_range(r, min: 0, max: 500000)
    end

    product_grains do |instance|
      if grains = instance.product_grains
        g = grains.is_a?(String) ? grains.to_i : grains
      else
        g = extract_grains(instance.title).try(:to_i) ||
          extract_grains(instance.keywords).try(:to_i)
      end
      restrict_to_range(g, min: 0, max: 400)
    end

    product_caliber do |instance|
      caliber = nil
      caliber_category = %w(rimfire_calibers handgun_calibers shotgun_calibers rifle_calibers).detect do |mapping_name|
        mapping = Stretched::Mapping.find(mapping_name)
        caliber = extract_metadata(:product_caliber, mapping, instance) ||
          extract_metadata(:title, mapping, instance) ||
          extract_metadata(:keywords, mapping, instance)
      end
      instance.product_caliber_category = caliber_category.split("_calibers").first if caliber_category
      caliber
    end

    product_manufacturer do |instance|
      mapping = Stretched::Mapping.find("manufacturers")
      manufacturer = extract_metadata(:product_manufacturer, mapping, instance) ||
        extract_metadata(:title, mapping, instance) ||
        extract_metadata(:keywords, mapping, instance)
      instance.delete(:title_tokens)
      instance.delete(:keyword_tokens)
      manufacturer
    end

    discount_in_cents do |instance|
      calculate_discount_in_cents(instance)
    end

    discount_percent do |instance|
      calculate_discount_percent(instance)
    end

    shipping_cost_in_cents do |instance|
      if instance.shipping_cost_in_cents.is_a?(String)
        instance.shipping_cost_in_cents.to_i
      else
        instance.shipping_cost_in_cents
      end
    end

  end
end

