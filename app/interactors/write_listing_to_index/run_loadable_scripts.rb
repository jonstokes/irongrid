class RunLoadableScripts
  include Interactor

    before do
      # The loadables sometimes use these messages
      context.message1 = context.listing_json.message1
      context.message2 = context.listing_json.message2
      context.message3 = context.listing_json.message3
      context.message4 = context.listing_json.message4
    end

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
          value.call(instance)
        end
      end
    end

end
