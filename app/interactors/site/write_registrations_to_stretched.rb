module Site
  class WriteRegistrationsToStretched
    include Interactor

    def call
      Stretched::Registration.create_from_source(context.site.registrations, context.user)
    end
  end
end