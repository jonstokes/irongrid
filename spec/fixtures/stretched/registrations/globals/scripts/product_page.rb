Stretched::Script.define "globals/scripts/product_page" do
  extensions 'globals/extensions/*'

  script do
    url do |instance|
      clean_up_url(instance.url)
    end

    title do |instance|
      next unless instance['title'].present?
      instance['title'].gsub!("\n", ' ')
      instance['title'].gsub!("\t", ' ')
      instance['title'].squeeze(' ')
    end

    availability do |instance|
      if %w(AuctionListing ClassifiedListing).include?(instance['type'])
        "in_stock"
      else
        instance['availability'].try(:downcase)
      end
    end

    image do |instance|
      if instance['image']
        clean_up_image_url(instance['image'])
      end
    end

    condition do |instance|
      instance['condition'].try(:downcase)
    end
    price_in_cents do |instance|
      convert_dollars_to_cents(instance['price_in_cents'])
    end

    sale_price_in_cents do |instance|
      convert_dollars_to_cents(instance['sale_price_in_cents'])
    end

    buy_now_price_in_cents do |instance|
      convert_dollars_to_cents(instance['buy_now_price_in_cents'])
    end

    current_bid_in_cents do |instance|
      convert_dollars_to_cents(instance['current_bid_in_cents'])
    end

    minimum_bid_in_cents do |instance|
      convert_dollars_to_cents(instance['minimum_bid_in_cents'])
    end

    reserve_in_cents do |instance|
      convert_dollars_to_cents(instance['reserve_in_cents'])
    end

    current_price_in_cents do |instance|
      case instance['type']
      when "AuctionListing"
        [
          instance['buy_now_price_in_cents'],
          instance['current_bid_in_cents'],
          instance['minimum_bid_in_cents'],
          instance['reserve_in_cents']
        ].compact.sort.last
      when "RetailListing"
        instance['sale_price_in_cents'] || instance['price_in_cents']
      when "ClassifiedListing"
        instance['price_in_cents']
      end
    end

    product_category1 do |instance|
      instance['product_category1'].try(:downcase)
    end

    product_category2 do |instance|
      instance['product_category2'].try(:downcase)
    end

    discount_in_cents do |instance|
      calculate_discount_in_cents(instance)
    end

    discount_percent do |instance|
      calculate_discount_percent(instance)
    end

    product_weight_shipping do |instance|
      if instance['product_weight_shipping']
        instance['product_weight_shipping'].to_f
      end
    end

    shipping_cost_in_cents do |instance|
      if instance['shipping_cost_in_cents'].is_a?(String)
        instance['shipping_cost_in_cents'].to_i
      else
        instance['shipping_cost_in_cents']
      end
    end

  end
end

