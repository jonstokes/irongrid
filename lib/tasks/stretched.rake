def register_globals
  Stretched::Extension.register_from_file("#{Rails.root}/spec/fixtures/stretched/registrations/extensions/conversions.rb")
  Stretched::Script.register_from_file("#{Rails.root}/spec/fixtures/stretched/registrations/scripts/globals/product_page.rb")
  Stretched::Script.register_from_file("#{Rails.root}/spec/fixtures/stretched/registrations/scripts/globals/validation.rb")
  Stretched::Registration.register_from_file("#{Rails.root}/spec/fixtures/stretched/registrations/globals.yml")
end

def register_site(domain)
  source = YAML.load_file("#{Figaro.env.sites_repo}/site_sources/#{domain.gsub(".","--")}.yml")['registrations']
  Stretched::Registration.register_from_source source
end

def domains
  YAML.load_file("#{Figaro.env.sites_repo}/sites/site_manifest.yml")
end

namespace :stretched do
  task :register_all => :environment do
    register_globals
    domains.each do |domain|
      register_site(domain)
    end
  end
end
