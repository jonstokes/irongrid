module Site
  class AddNew
    include Interactor

    def call
      local_domains.each do |domain|
        next if existing_domains.include?(domain)
        Site::LoadFromLocal.call(
            domain:    domain,
            directory: directory,
            user:      user
        )
      end
    end

    def directory
      context.directory
    end

    def user
      context.user
    end

    def local_domains
      @local_domains ||= YAML.load_file("#{directory}/site_manifest.yml")
    end

    def existing_domains
      @existing_domains ||= IronCore::Site.domains
    end

  end
end