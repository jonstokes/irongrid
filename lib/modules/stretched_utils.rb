module StretchedUtils

  def self.register_globals(user=nil)
    user ||= stretched_user
    StretchedUtils::Utils.new(user).register_globals
  end

  def self.stretched_user
    ENV['STRETCHED_USER'] || Stretched::Settings.user
  end


  class Utils
    include Bellbro::Ringable
    attr_reader :user

    def initialize(user)
      raise "Sites repo not found at #{Figaro.env.sites_repo}" unless Dir.exists?(Figaro.env.sites_repo)
      @user = user
      Stretched::Settings.configure { |c| c.cache_registrations = false }
    end

    def register_extensions
      Dir["#{Figaro.env.sites_repo}/globals/extensions/*.rb"].each do |filename|
        ring "Creating extension from #{filename} for user #{user}"
        Stretched::Extension.create_from_file(filename, user)
      end
    end

    def register_scripts
      Dir["#{Figaro.env.sites_repo}/globals/scripts/*.rb"].each do |filename|
        ring "Creating script from #{filename} for user #{user}"
        Stretched::Script.create_from_file(filename, user)
      end
    end

    def register_mappings
      Dir["#{Figaro.env.sites_repo}/globals/mappings/*.yml"].each do |filename|
        ring "Creating mapping from #{filename} for user #{user}"
        Stretched::Mapping.create_from_file(filename, user)
      end
    end

    def create_registrations
      ring "Creating registrations from globals/registrations.yml for user #{user}"
      Stretched::Registration.create_from_file("#{Figaro.env.sites_repo}/globals/registrations.yml", user)
    end

    def register_globals
      register_extensions
      register_scripts
      register_mappings
      create_registrations
    end
  end

end
