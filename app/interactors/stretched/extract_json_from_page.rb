module Stretched
  class ExtractJsonFromPage
    include Interactor
    include DocQueries

    def perform
      object_adapter.each do |attr, setters|
        setters.detect do |setter|
          next unless result = set(attr) { _run_setter(setter) }
        end
      end
    end

    def set(attribute, &block)
      # NOTE: set has to return true in every case but no valid match!

      result = yield
      if _result_is_valid?(attribute, result)
        context[:json_object_output] ||= {}
        context[:json_object_output][attribute] = result
        true
      else
        false
      end
    end

    private

    def _result_is_valid?(attribute, value)
      object_adapter.validate(attribute, value)
    end

    def _run_setter(setter)
      return self.send(setter) if setter.is_a?(String)

      method = setter.keys.detect { |k| k != "filters" }
      args = setter[method]
      result = self.send(method, args)
      result = filters(result, setter["filters"]) if setter["filters"]
      result
    end

  end
end
