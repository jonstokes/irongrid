module Site
  class WriteScriptsToStretched
    include Interactor

    def call
      # Load scripts
      context.stretched_scripts.each do |file|
        puts "Registering script #{file} for stretched user #{context.user}"
        Stretched::Script.create_from_file(
            file,
            context.user
        )
      end
    end
  end
end