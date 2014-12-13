class WriteListingToIndex
  class RunLoadableScripts
    include Interactor

    before do
      # Loadables will blow up if these are nil
      context.listing.price ||= {}
      context.product.weight ||= {}
      context.listing.shipping ||= {}

      # Later there will be elsif clauses for bunkerplex, etc.
      if ironsights?
        extend Ironsights::ListingSetters
      end
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

    after do
      context.listing.price = nil if context.listing.price.empty?
      context.product.weight = nil if context.product.weight.empty?
      context.listing.shipping = nil if context.listing.shipping.empty?
    end

    def extend_runner(runner)
      if ironsights?
        runner.send(:extend, Ironsights::ListingCalculations)
      end
    end

    def ironsights?
      context.listing.engine == 'ironsights'
    end

  end
end
