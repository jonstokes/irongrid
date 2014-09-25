def register_stretched_globals
  Stretched::Extension.create_from_file("#{Rails.root}/spec/fixtures/stretched/registrations/extensions/conversions.rb")
  Stretched::Script.create_from_file("#{Rails.root}/spec/fixtures/stretched/registrations/scripts/globals/product_page.rb")
  Stretched::Script.create_from_file("#{Rails.root}/spec/fixtures/stretched/registrations/scripts/globals/validation.rb")
  Stretched::Registration.create_from_file("#{Rails.root}/spec/fixtures/stretched/registrations/globals.yml")
end

def register_globals
  Dir["#{Rails.root}/spec/fixtures/stretched/registrations/globals/extensions/*.rb"].each do |filename|
    Stretched::Extension.create_from_file(filename)
  end

  Dir["#{Rails.root}/spec/fixtures/stretched/registrations/globals/scripts/*.rb"].each do |filename|
    Stretched::Script.create_from_file(filename)
  end

  Dir["#{Rails.root}/spec/fixtures/stretched/registrations/globals/mappings/*.yml"].each do |filename|
    Stretched::Mapping.create_from_file(filename)
  end

  Stretched::Registration.create_from_file("#{Rails.root}/spec/fixtures/stretched/registrations/globals/registrations.yml")
end

def register_site(domain)
  source = YAML.load_file("#{Rails.root}/spec/fixtures/sites/#{domain.gsub(".","--")}.yml")['registrations']
  Stretched::Registration.create_from_source source
end
