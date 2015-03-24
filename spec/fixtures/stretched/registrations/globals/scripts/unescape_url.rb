Stretched::Script.define do
  script "globals/unescape_url" do
    product_link do |instance|
      Addressable::URI.unescape(instance.product_link) if instance.product_link
    end
  end
end
