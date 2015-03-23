module Site
  class WriteScriptsToStretched
    include Interactor
    include Shout

    def call
      # Load scripts
      context.stretched_scripts.each do |file|
        log "Registering script #{file} for stretched user #{context.user}"
        Stretched::Script.create_from_file(
            file,
            context.user
        )
      end
    end
  end
end