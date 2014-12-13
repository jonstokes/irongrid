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

    def discount(value)
      listing.discount = value
    end

    def discount_with_shipping(value)
      listing.with_shipping.discount = value
    end

    def price_per_round(value)
      listing.price.per_round = value
    end

    def price_per_round_with_shipping(value)
      listing.with_shipping.price.per_round = value
    end

    def price_with_shipping(value)
      listing.with_shipping = value
    end

    def listing
      context.listing
    end

  end
end
