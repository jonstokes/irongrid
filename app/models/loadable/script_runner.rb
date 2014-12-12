module Loadable
  class ScriptRunner

    attr_reader :attributes
    attr_accessor :context

    def initialize
      @attributes = {}
    end

    def listing
      @context.listing
    end

    def product
      @context.product
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

    def calculate_discount_in_cents(list_price, sale_price)
      return 0 unless list_price > sale_price
      list_price - sale_price
    end

    def calculate_discount_percent(list_price, sale_price)
      return 0 unless (list_price > sale_price) && !sale_price.zero?
      (list_price.to_f / sale_price.to_f).round * 100
    end

    def method_missing(name, *args, &block)
      if block_given?
        attributes[name.to_s] = block
      else
        attributes[name.to_s] = args[0]
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
