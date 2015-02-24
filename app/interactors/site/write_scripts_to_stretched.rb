module Site
  class WriteScriptsToStretched
    include Interactor
    include Bellbro::Ringable

    def call
      # Load scripts
      context.stretched_scripts.each do |file|
        ring "Registering script #{file} for stretched user #{context.user}"
        Stretched::Script.create_from_file(
            file,
            context.user
        )
      end
    end
  end
end