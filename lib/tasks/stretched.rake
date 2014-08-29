def register_globals
  Stretched::Extension.register_from_file("#{Rails.root}/spec/fixtures/stretched/registrations/extensions/conversions.rb")
  Stretched::Script.register_from_file("#{Rails.root}/spec/fixtures/stretched/registrations/scripts/globals/product_page.rb")
  Stretched::Script.register_from_file("#{Rails.root}/spec/fixtures/stretched/registrations/scripts/globals/validation.rb")
  Stretched::Registration.register_from_file("#{Rails.root}/spec/fixtures/stretched/registrations/globals.yml")
end

def register_repo_scripts
  script_list = []
  script_list << "#{Figaro.env.sites_repo}/globals/scripts/validate_price_avail_title.rb"
  script_list << "#{Figaro.env.sites_repo}/globals/scripts/validate_price_or_avail_title.rb"
  script_list << "#{Figaro.env.sites_repo}/globals/scripts/validate_price_or_avail_title_desc.rb"
  script_list << "#{Figaro.env.sites_repo}/globals/scripts/validate_price_or_avail_title_image_desc.rb"
  script_list << "#{Figaro.env.sites_repo}/globals/scripts/validate_price_title.rb"
  script_list << "#{Figaro.env.sites_repo}/globals/scripts/validate_price_title_desc.rb"
  script_list << "#{Figaro.env.sites_repo}/globals/scripts/validate_price_title_image.rb"
  script_list << "#{Figaro.env.sites_repo}/globals/scripts/validate_price_title_image_desc.rb"
  script_list << "#{Figaro.env.sites_repo}/globals/scripts/validate_title_image_desc.rb"
  script_list.map { |script| Stretched::Script.register_from_file(script) }
end

def register_site(domain)
  source = YAML.load_file("#{Figaro.env.sites_repo}/site_sources/#{domain.gsub(".","--")}.yml")['registrations']
  Stretched::Registration.register_from_source source
end

def domains
  ParserTest.all.map(&:seller_domain).uniq
end

namespace :stretched do
  task :register_all => :environment do
    register_globals
    register_repo_scripts
    domains.each do |domain|
      begin
        register_site(domain)
      rescue Exception => e
        puts e.message
        next
      end
    end
  end
end
