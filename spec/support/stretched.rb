def register_stretched_globals
  Stretched::Extension.register_from_file("#{Rails.root}/spec/fixtures/stretched/registrations/extensions/conversions.rb")
  Stretched::Script.register_from_file("#{Rails.root}/spec/fixtures/stretched/registrations/scripts/globals/product_page.rb")
  Stretched::Script.register_from_file("#{Rails.root}/spec/fixtures/stretched/registrations/scripts/globals/validation.rb")
  Stretched::Registration.register_from_file("#{Rails.root}/spec/fixtures/stretched/registrations/globals.yml")
end
