Stretched::Script.define "www.midwayusa.com/invalidate_with_xpath" do
  extensions 'globals/extensions/*'
  script do
    valid do |instance|
      if doc.xpath("//div[@id='characteristicBlock']/select/option").any?
        false
      else
        instance.valid
      end
    end
  end
end