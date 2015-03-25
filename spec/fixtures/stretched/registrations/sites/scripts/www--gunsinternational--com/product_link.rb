Stretched::Script.define "www.gunsinternational.com/product_link" do
  extensions 'globals/extensions/*'
  script do
    product_link do |instance|
      if instance.product_link && instance.product_link['&CFID']
        instance.product_link.split('&CFID').first
      else
        instance.product_link
      end
    end

  end
end

