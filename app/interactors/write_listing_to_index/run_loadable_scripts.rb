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

      Stretched::Extension.register_all if Stretched::Extension.registry.empty?
    end

    def call
      context.site.loadables.each do |script_name|
        runner = Stretched::Script.runner(key: script_name)
        runner.set_context(
            listing:      context.listing,
            product:      context.product,
            listing_json: context.listing_json
        )
        instance = runner.run
        instance.each do |setter, value|
          self.send(setter, value) if value
        end
      end
    end

    after do
      context.listing.price = nil if context.listing.price.empty?
      context.product.weight = nil if context.product.weight.empty?
      context.listing.shipping = nil if context.listing.shipping.empty?
    end

    def ironsights?
      context.listing.engine == 'ironsights'
    end

  end
end
