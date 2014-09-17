Stretched::Script.define do
  script "globals/validate_title_image_description" do
    valid do |instance|
        instance.title? &&
        instance.image? &&
        instance.description?
    end
  end
end
