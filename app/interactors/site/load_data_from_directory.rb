module Site
  class LoadDataFromDirectory
    include Interactor

    before do
      context.filename = filename
    end

    def call
      context.site_data = YAML.load_file(filename)
      context.stretched_scripts = Dir["#{directory}/stretched_scripts/#{domain_dash}/*.rb"]
      context.loadables = Dir["#{directory}/irongrid_scripts/#{domain_dash}.rb"]
    end

    def filename
      "#{directory}/#{domain_dash}.yml"
    end

    def domain_dash
      domain.gsub(".","--")
    end

    def directory
      context.directory
    end

    def user
      context.user
    end

    def domain
      context.domain
    end

  end
end