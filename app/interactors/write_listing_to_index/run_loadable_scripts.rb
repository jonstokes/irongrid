class WriteListingToIndex
  class RunLoadableScripts
    include Interactor

    before do
      # Loadables will blow up if these are nil
      context.listing.price ||= {}
      context.product.weight ||= {}
      context.listing.shipping ||= {}
    end

    def call
      context.site.loadables.each do |script_name|
        runner = Loadable::Script.runner(script_name)
        extend_runner(runner)
        runner.with_context(context) do
          runner.actions.each do |setter, action|
            value = action.call
            self.send(setter, value) if value
          end
        end
      end
    end

    def extend_runner(runner)
      runner.send(:extend, Ironsights::ListingCalculations)
    end

    def shipping_cost(value)
      context.listing.shipping.cost = value
    end


  end
end
