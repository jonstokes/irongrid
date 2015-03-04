module Site
  class LoadDataFromDirectory
    include Interactor

    def call
      context.site_data = YAML.load_file(filename)
      context.stretched_scripts = Dir["#{directory}/stretched_scripts/#{domain_dash}/*.rb"]
      context.loadables = Dir["#{directory}/irongrid_scripts/#{domain_dash}.rb"]
    end

    def filename
      context.filename ||= "#{directory}/#{domain_dash}.yml"
    end

    def directory
      context.directory ||= IronCore::Site.sites_dir
    end

    def domain_dash
      domain.gsub(".","--")
    end

    def domain
      context.domain
    end

  end
end