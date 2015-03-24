Stretched::Script.define "globals/validate_title_image_description" do
  extensions 'globals/extensions/*'
  script do
    valid do |instance|
        !!(instance['title'] &&
        instance['image'] &&
        instance['description'])
    end
  end
end
