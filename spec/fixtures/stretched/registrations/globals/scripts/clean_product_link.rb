Stretched::Script.define "globals/clean_product_link" do
  extensions 'globals/extensions/*'
  script do
    product_link do |instance|
      if instance['product_link'] && instance['product_link'][';jsessionid']
        instance['product_link'].split(';jsessionid').first
      else
        instance['product_link']
      end
    end
  end
end

