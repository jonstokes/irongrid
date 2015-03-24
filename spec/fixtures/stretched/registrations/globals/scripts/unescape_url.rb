Stretched::Script.define "globals/unescape_url" do
  extensions 'globals/extensions/*'
  script do
    product_link do |instance|
      Addressable::URI.unescape(instance['product_link']) if instance['product_link']
    end
  end
end
