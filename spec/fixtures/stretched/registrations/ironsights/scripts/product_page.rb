Stretched::Script.define "ironsights/scripts/product_page" do
  extensions [
     'globals/extensions/*',
     'ironsights/extensions/*'
   ]

  script do
    product_number_of_rounds do |instance|
      if numrounds = instance['product_number_of_rounds']
        r = numrounds.is_a?(String) ? numrounds.delete(",").to_i : numrounds
      else
        r = extract_number_of_rounds(instance['title']).try(:to_i) ||
          extract_number_of_rounds(instance['keywords']).try(:to_i)
      end
      restrict_to_range(r, min: 0, max: 500000)
    end

    product_grains do |instance|
      if grains = instance['product_grains']
        g = grains.is_a?(String) ? grains.to_i : grains
      else
        g = extract_grains(instance['title']).try(:to_i) ||
          extract_grains(instance['keywords']).try(:to_i)
      end
      restrict_to_range(g, min: 0, max: 400)
    end

    product_category1 do |instance|
      if instance['title'] && (instance['title'][/snap\W*cap/i] || instance['title'][/dummy/i])
        'accessories'
      else
        instance['product_category1']
      end
    end

    product_caliber do |instance|
      caliber = nil
      caliber_category = %w(rimfire_calibers handgun_calibers shotgun_calibers rifle_calibers).detect do |mapping_name|
        mapping = load_registration(type: :mapping, key: mapping_name)
        caliber = extract_metadata(:product_caliber, mapping, instance) ||
          extract_metadata(:title, mapping, instance) ||
          extract_metadata(:keywords, mapping, instance)
      end
      instance['product_caliber_category'] = caliber_category.split("_calibers").first if caliber_category
      caliber
    end

    product_caliber_category do |instance|
      instance['product_caliber_category'].try(:downcase)
    end

    product_casing do |instance|
      instance['product_casing'].try(:downcase)
    end

    product_casing_condition do |instance|
      instance['product_casing_condition'].try(:downcase) || 'new'
    end

    product_manufacturer do |instance|
      mapping = load_registration(type: :mapping, key: 'manufacturers')
      manufacturer = extract_metadata(:product_manufacturer, mapping, instance) ||
        extract_metadata(:title, mapping, instance) ||
        extract_metadata(:keywords, mapping, instance)
      instance.delete('title_tokens')
      instance.delete('keyword_tokens')
      manufacturer
    end

    product_bullet_type do |instance|
      extract_bullet_type(instance['product_bullet_type'])
    end

    product_load_type do |instance|
      extract_load_type(instance['product_load_type'])
    end

    product_velocity do |instance|
      instance['product_velocity'].to_i if instance['product_velocity'].present?
    end

    product_frangible do |instance|
      instance['product_frangible'].present?
    end
  end
end
