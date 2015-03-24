Stretched::Script.define "www.brownells.com/image_fix" do
  extensions 'globals/extensions/*'
  script do
    image do |instance|
      if instance.image.present?
        instance.image.sub('t_', 'p_')
      end
    end
  end
end