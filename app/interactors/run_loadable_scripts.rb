class RunLoadableScripts
  include Interactor

    def perform
      site.loadables.each do |script_name|
        runner = Loadable::Script.runner(script_name)
        runner.attributes.each do |attribute_name, value|
          result = value.is_a?(Proc) ? value.call(Hashie::Mash.new(context)) : value
          context.listing[attribute_name] = result
        end
      end
    end

end
