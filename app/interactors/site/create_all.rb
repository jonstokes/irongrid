module Site
  class CreateAll
    include Interactor

    def call
      domains.each do |domain|
        Site::LoadFromLocal.call(
            domain:    domain,
            directory: directory,
            user:      user
        )
      end
    end

    def domains
      @domains ||= YAML.load_file("#{directory}/site_manifest.yml")
    end

    def directory
      context.directory
    end

    def user
      context.user
    end
  end
end