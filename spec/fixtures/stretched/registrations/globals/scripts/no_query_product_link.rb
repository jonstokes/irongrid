Stretched::Script.define do
  script "globals/no_query_product_link" do
    product_link do |instance|
      if instance.product_link && instance.product_link['?']
        instance.product_link.split('?').first
      else
        instance.product_link
      end
    end

  end
end

