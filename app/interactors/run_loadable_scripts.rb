class RunLoadableScripts
  include Interactor

    def perform
      site.loadables.each do |script_name|
        runner = Loadable::Script.runner(script_name)
        runner.attributes.each do |attribute_name, value|
          result = value.is_a?(Proc) ? value.call(Hashie::Mash.new(context)) : value
          context[attribute_name.to_s] = result
        end
      end
    end

end
