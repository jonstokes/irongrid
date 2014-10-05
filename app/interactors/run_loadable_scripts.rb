class RunLoadableScripts
  include Interactor

    def perform
      site.loadables.each do |script_name|
        runner = Loadable::Script.runner(script_name)
        runner.run(context)
      end
    end

end
