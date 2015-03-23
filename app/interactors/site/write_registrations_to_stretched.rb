module Site
  class WriteRegistrationsToStretched
    include Interactor
    include Shout

    def call
      log "Creating registrations for site #{context.site.domain} for user #{user}"
      Stretched::Registration.create_from_source(context.site.registrations, user)
    end

    def user
      context.user ||= Stretched::Settings.user
    end

  end
end