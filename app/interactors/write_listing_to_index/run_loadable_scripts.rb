class WriteListingToIndex
  class RunLoadableScripts
    include Interactor

    before do
      # The loadables sometimes use these messages
      context.message1 = context.listing_json.message1
      context.message2 = context.listing_json.message2
      context.message3 = context.listing_json.message3
      context.message4 = context.listing_json.message4

      # Loadables will blow up if these are nil
      context.listing.shipping ||= {}
      context.listing.price ||= {}
      context.product.weight ||= {}
    end

    def call
      context.site.loadables.each do |script_name|
        runner = Loadable::Script.runner(script_name)
        runner.attributes.each do |attribute_name, value|
          value.call(context)
        end
      end
    end
  end
end
