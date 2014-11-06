module Loadable
  class ScriptRunner

    attr_reader :attributes

    def initialize
      @attributes = {}
    end

    def calculate_discount_in_cents(list_price, sale_price)
      return 0 unless list_price > sale_price
      list_price - sale_price
    end

    def calculate_discount_percent(list_price, sale_price)
      return 0 unless list_price > sale_price
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
