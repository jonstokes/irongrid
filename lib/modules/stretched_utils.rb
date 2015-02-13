module StretchedUtils

  def self.register_globals(user)
    StretchedUtils::Utils.new(user).register_globals
  end

  def self.register_site(domain, user)
    StretchedUtils::Utils.new(user).register_site(domain)
  end

  def self.register_sites(user)
    StretchedUtils::Utils.new(user).register_sites
  end

  class Utils
    attr_reader :user

    def initialize(user)
      raise "Sites repo not found at #{Figaro.env.sites_repo}" unless Dir.exists?(Figaro.env.sites_repo)
      @user = user
      Stretched::Settings.configure { |c| c.cache_registrations = false }
    end

    def register_globals
      Dir["#{Figaro.env.sites_repo}/globals/extensions/*.rb"].each do |filename|
        outlog "Creating extension from #{filename} for user #{user}"
        Stretched::Extension.create_from_file(filename, user)
      end

      Dir["#{Figaro.env.sites_repo}/globals/scripts/*.rb"].each do |filename|
        outlog "Creating script from #{filename} for user #{user}"
        Stretched::Script.create_from_file(filename, user)
      end

      Dir["#{Figaro.env.sites_repo}/globals/mappings/*.yml"].each do |filename|
        outlog "Creating mapping from #{filename} for user #{user}"
        Stretched::Mapping.create_from_file(filename, user)
      end

      outlog "Creating registrations from globals/registrations.yml for user #{user}"
      Stretched::Registration.create_from_file("#{Figaro.env.sites_repo}/globals/registrations.yml", user)
    end

    def register_site(domain)
      filename = "#{Figaro.env.sites_repo}/sites/#{domain.gsub(".","--")}.yml"
      outlog "Registering #{domain} from #{filename} for user #{user}"
      source = YAML.load_file(filename)['registrations']
      Stretched::Registration.create_from_source(source, user)

      Dir["#{Figaro.env.sites_repo}/sites/stretched_scripts/#{domain.gsub(".","--")}/*.rb"].each do |filename|
        outlog "Creating script for #{domain} from #{filename} for user #{user}"
        Stretched::Script.create_from_file(filename, user)
      end
    end

    def register_sites
      domains = YAML.load_file("#{Figaro.env.sites_repo}/sites/site_manifest.yml")
      domains.each { |domain| register_site(domain) }
    end

    def outlog(string)
      return if Rails.env.test?
      puts "# #{string}"
    end
  end

end
