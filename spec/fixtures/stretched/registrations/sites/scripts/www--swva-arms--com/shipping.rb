Stretched::Script.define "www.swva-arms.com/shipping" do
  extensions 'globals/extensions/*'
  script do
    shipping_cost do
      if listing.title[/FLAT RATE/]
        1300
      end
    end
  end
end
