module Site
  class WriteLoadablesToIronGrid
    include Interactor
    include Shout

    def call
      return if context.loadables.empty?
      log "Loading IronGrid loadable #{context.loadables} for site #{context.site.domain}"
      Loadable::Script.create_from_file(context.loadables.first)
    end
  end
end