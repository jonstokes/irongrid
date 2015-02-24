module IronCore
  class UpdateAll
    include Interactor

    def call
      existing_domains.each do |domain|
        Site::UpdateFromLocal.call(
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

    def existing_domains
      @existing_domains ||= IronCore::Site.domains
    end
  end
end