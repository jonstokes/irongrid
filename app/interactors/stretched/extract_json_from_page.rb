module Stretched
  class ExtractJsonFromPage
    include Interactor

    attr_accessor :instance, :adapter

    def perform
      @adapter = context[:adapter] || ObjectAdapter.find(context[:adapter_name])

      context[:json_objects] = page.doc.xpath(adapter.xpath).map do |node|
        # Run JSON setters
        instance = read_with_json(node, Hashie::Mash.new)

        # Run ruby setters
        adapter.scripts.each do |script_name|
          instance = read_with_script(node, script_name, instance)
        end if adapter.scripts

        # Validate results
        instance.select { |attribute, value| adapter.validate(attribute, value) }
      end
    end

    #
    # private
    #

    def read_with_json(node, instance)
      runner = ScriptRunner.new
      runner.set_context(doc: node, page: page, browser_session: context[:browser_session])
      adapter.attribute_setters.each do |attribute_name, setters|
        raise "Undefined property #{attribute_name} in schema #{adapter.schema_key}" unless adapter.validate_property(attribute_name)
        setters.each do |setter|
          if setter.is_a?(Hash)
            method = setter.reject {|k,v| k == "filters"}.first.first
            args = setter[method]
            result = args.nil? ? runner.send(method) : runner.send(method, args)
          else
            result = runner.send(setter)
          end
          result = runner.filters(result, setter["filters"]) if setter["filters"]
          instance[attribute_name] = result

        end
      end

      instance
    end

    def read_with_script(node, script_name, instance)
      runner = Script.runner(script_name)
      runner.set_context(doc: node, page: page, browser_session: context[:browser_session])
      runner.attributes.each do |attribute_name, value|
        raise "Undefined property #{attribute_name} in schema #{adapter.schema_key}" unless adapter.validate_property(attribute_name)
        result = value.is_a?(Proc) ? value.call(instance) : value
        instance[attribute_name.to_s] = result
      end

      instance
    end

  end
end
