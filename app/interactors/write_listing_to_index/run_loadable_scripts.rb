class WriteListingToIndex
  class RunLoadableScripts
    include Interactor

    before do
      # Loadables will blow up if these are nil
      context.product.weight ||= {}
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
          context.listing.send("#{setter}=", value)
        end
      end
    end

    after do
      context.product.weight = nil if context.product.weight.empty?
    end

    def ironsights?
      context.listing.engine == 'ironsights'
    end
  end
end
