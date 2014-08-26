def register_stretched_globals
  Stretched::Extension.register_from_file("#{Rails.root}/spec/fixtures/stretched/registrations/extensions/conversions.rb")
  Stretched::Script.register_from_file("#{Rails.root}/spec/fixtures/stretched/registrations/scripts/globals/product_page.rb")
  Stretched::Script.register_from_file("#{Rails.root}/spec/fixtures/stretched/registrations/scripts/globals/validation.rb")
  Stretched::Registration.register_from_file("#{Rails.root}/spec/fixtures/stretched/registrations/globals.yml")
end

def register_site(domain)
  source = YAML.load_file("#{Rails.root}/spec/fixtures/sites/#{domain.gsub(".","--")}.yml")['registrations']
  Stretched::Registration.register_from_source source
end
