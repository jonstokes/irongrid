def register_globals
  Stretched::Registration.register_from_file("#{Figaro.env.sites_repo}/globals/registrations.yml")
end

def register_extensions
  Dir.glob("#{Figaro.env.sites_repo}/globals/extensions/*.rb").each do |filename|
    puts "# Registering #{filename}..."
    Stretched::Extension.register_from_file(filename)
  end
end

def register_mappings
  Dir.glob("#{Figaro.env.sites_repo}/globals/mappings/*.yml").each do |filename|
    puts "# Registering #{filename}..."
    Stretched::Mapping.register_from_file(filename)
  end
end

def register_scripts
  Dir.glob("#{Figaro.env.sites_repo}/globals/scripts/*.rb").each do |filename|
    puts "# Registering #{filename}..."
    Stretched::Script.register_from_file(filename)
  end
  Dir.glob("#{Figaro.env.sites_repo}/sites/irongrid_scripts/*.rb").each do |filename|
    puts "# Registering #{filename}..."
    Stretched::Script.register_from_file(filename)
  end
  Dir.glob("#{Figaro.env.sites_repo}/sites/stretched_scripts/*.rb").each do |filename|
    puts "# Registering #{filename}..."
    Stretched::Script.register_from_file(filename)
  end
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
    register_mappings
    register_extensions
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
