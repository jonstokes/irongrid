Stretched::Script.define "globals/validate_price_or_availability_title_image_description" do
  extensions 'globals/extensions/*'
  script do
    valid do |instance|
      !!((instance['current_price_in_cents'] || instance['price_on_request'] || instance['availability']) &&
        instance['title'] &&
        instance['image'] &&
        instance['description'])
    end
  end
end
