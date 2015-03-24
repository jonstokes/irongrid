Stretched::Script.define "globals/validate_price_availability_title" do
  extensions 'globals/extensions/*'
  script do
    valid do |instance|
      !!((instance['current_price_in_cents'] || instance['price_on_request']) &&
        instance['availability'] &&
        instance['title'])
    end
  end
end
