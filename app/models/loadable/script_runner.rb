module Loadable
  class ScriptRunner

    attr_reader :actions
    attr_accessor :context

    def initialize
      @actions = {}
    end

    def listing
      @context.listing
    end

    def product
      @context.product
    end

    def category1
      @context.product.category1
    end

    def weight
      @context.product.weight.shipping
    end

    def price
      @context.listing.price.current
    end

    def listing_json
      @context.listing_json
    end

    def message1
      @context.listing_json.message1
    end

    def message2
      @context.listing_json.message2
    end

    def message3
      @context.listing_json.message3
    end

    def message4
      @context.listing_json.message4
    end

    def with_context(new_context)
      @context = new_context
      yield
      @context = nil
    end
    
    def method_missing(name, *args, &block)
      if block_given?
        actions[name.to_s] = block
      else
        actions[name.to_s] = args[0]
      end
    rescue RuntimeError => e
      if !!e.message[/add a new key into hash during iteration/]
        super
      else
        raise e
      end
    end
  end
end
