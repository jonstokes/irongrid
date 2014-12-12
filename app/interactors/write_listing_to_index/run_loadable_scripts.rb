class WriteListingToIndex
  class RunLoadableScripts
    include Interactor

    before do
      # Loadables will blow up if these are nil
      context.listing.price ||= {}
      context.product.weight ||= {}
    end

    def call
      context.site.loadables.each do |attribute, script_name|
        runner = Loadable::Script.runner(script_name)
        runner.with_context(context) do
          runner.actions.each_value do |action|
            action.call
          end
        end
      end
    end
  end
end
