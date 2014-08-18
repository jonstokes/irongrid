module Stretched
  class ExtractJsonFromPage
    include Interactor

    attr_accessor :instance, :adapter

    def setup
      Extension.register_all
    end

    def perform
      @adapter = context[:adapter] || ObjectAdapter.find(context[:adapter_name])

      context[:json_objects] = page.doc.xpath(adapter.xpath).map do |node|
        # Run JSON setters
        runner = Script.runner
        runner.set_context(doc: node, page: page, browser_session: context[:browser_session])
        instance = read_with_json(
          runner: runner,
          node: node,
          instance: Hashie::Mash.new
        )

        # Run ruby setters
        adapter.scripts.each do |script_name|
          runner = Script.runner(script_name)
          runner.set_context(doc: node, page: page, browser_session: context[:browser_session])
          instance = read_with_script(
            runner: runner,
            node: node,
            instance: instance
          )
        end if adapter.scripts

        # Validate results
        instance.select { |attribute, value| adapter.validate(attribute, value) }
      end
    end

    #
    # private
    #

    def read_with_json(opts)
      runner, node, instance = opts[:runner], opts[:node], opts[:instance]
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

    def read_with_script(opts)
      runner, node, instance = opts[:runner], opts[:node], opts[:instance]
      runner.attributes.each do |attribute_name, value|
        raise "Undefined property #{attribute_name} in schema #{adapter.schema_key}" unless adapter.validate_property(attribute_name)
        result = value.is_a?(Proc) ? value.call(instance) : value
        instance[attribute_name.to_s] = result
      end

      instance
    end

  end
end
