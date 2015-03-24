module Site
  class LoadDataFromDirectory
    include Interactor

    def call
      context.site_data = YAML.load_file(filename)
      context.scripts = Dir["#{directory}/scripts/#{domain_dash}/*.rb"]
    end

    def filename
      context.filename ||= "#{directory}/#{domain_dash}.yml"
    end

    def directory
      context.directory ||= SiteLibrary::Utils.sites_dir
    end

    def domain_dash
      domain.gsub(".","--")
    end

    def domain
      context.domain
    end

  end
end