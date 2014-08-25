module Stretched
  class ExtractJsonFromPage
    include Interactor

    attr_accessor :instance, :adapter

    def setup
      Extension.register_all
      @adapter = context[:adapter] || ObjectAdapter.find(context[:adapter_name])
    end

    def perform
      context[:json_objects] = page.doc.xpath(adapter.xpath).map do |node|
        instance = Hashie::Mash.new
        instance = run_json_setters(instance, node)
        instance = run_ruby_setters(instance, node)
        instance.select { |attribute, value| adapter.validate(attribute, value) }

        { page: page.to_hash, object: instance }
      end
    end

    #
    # private
    #

    def run_json_setters(instance, node)
      runner = Script.runner
      runner.set_context(context)
      read_with_json(
        node: node,
        runner: runner,
        instance: instance
      )
    end

    def run_ruby_setters(instance, node)
      return instance unless adapter.scripts
      adapter.scripts.each do |script_name|
        runner = Script.runner(script_name)
        runner.set_context(context)
        instance = read_with_script(
          node: node,
          runner: runner,
          instance: instance
        )
      end
      instance
    end

    def read_with_json(opts)
      runner, node, instance = opts[:runner], opts[:node], opts[:instance]
      adapter.attribute_setters.each do |attribute_name, setters|
        raise "Undefined property #{attribute_name} in schema #{adapter.schema_key}" unless adapter.validate_property(attribute_name)
        setters.detect do |setter|
          if setter.is_a?(Hash)
            method = setter.reject {|k,v| k == "filters"}.first.first
            args = setter[method]
            result = args.nil? ? runner.send(method) : runner.send(method, args)
          else
            result = runner.send(setter)
          end
          result = runner.filters(result, setter["filters"]) if setter["filters"]
          instance[attribute_name] = result if result

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
