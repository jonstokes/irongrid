Stretched::Script.define "globals/validate_url_price_title" do
  extensions 'globals/extensions/*'
  script do
    valid do |instance|
      !!((instance['current_price_in_cents'] || instance['price_on_request']) &&
        instance['title'] && instance['url'])
    end
  end
end
