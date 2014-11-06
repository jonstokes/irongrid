class RunLoadableScripts
  include Interactor

    def call
      context.site.loadables.each do |script_name|
        runner = Loadable::Script.runner(script_name)
        instance = Hashie::Mash.new(
            listing:  context.listing,
            listing_json: context.listing_json,
            message1: context.message1,
            message2: context.message2,
            message3: context.message3,
            message4: context.message4
        )
        runner.attributes.each do |attribute_name, value|
          result = value.is_a?(Proc) ? value.call(instance) : value
          context.listing[attribute_name] = result
        end
      end
    end

end
