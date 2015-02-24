module Site
  class WriteLoadablesToIronGrid
    include Interactor
    include Bellbro::Ringable

    def call
      return if context.loadables.empty?
      ring "Loading IronGrid loadable #{context.loadables} for site #{context.site.domain}"
      Loadable::Script.create_from_file(context.loadables.first)
    end
  end
end