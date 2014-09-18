def register_globals
  Stretched::Extension.register_from_file("#{Figaro.env.sites_repo}/globals/extensions/conversions.rb")
  Stretched::Script.register_from_file("#{Figaro.env.sites_repo}/globals/scripts/product_page.rb")
  Stretched::Registration.register_from_file("#{Figaro.env.sites_repo}/globals/registrations.yml")
end

def register_scripts
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
  Dir.glob("#{Figaro.env.sites_repo}/sites/scripts/*.rb").each do |script_path|
    script_list << script_path
  end
  script_list.map { |script| Stretched::Script.register_from_file(script) }
end

def register_sites
  Site.each do |site|
    begin
      site.register
    rescue Exception => e
      puts e.message
      next
    end
  end
end

namespace :stretched do
  task :register_all => :environment do
    register_globals
    register_scripts
    register_sites
  end

  task :register_globals => :environment do
    register_globals
  end

  task :register_sites => :environment do
    register_sites
  end

  task :register_scripts => :environment do
    register_scripts
  end

end
