Stretched::Script.define "www.opticsplanet.com/unique_title"do
  extensions 'globals/extensions/*'
  script  do
    title do |instance|
      if instance.product_mpn
        "#{instance.title} #{instance.product_mpn}"
      else
        instance.title
      end
    end
  end
end