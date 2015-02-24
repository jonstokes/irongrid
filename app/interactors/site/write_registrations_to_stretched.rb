module Site
  class WriteRegistrationsToStretched
    include Interactor
    include Bellbro::Ringable

    def call
      ring "Creating registrations for site #{context.site.domain} for user #{context.user}"
      Stretched::Registration.create_from_source(context.site.registrations, context.user)
    end
  end
end