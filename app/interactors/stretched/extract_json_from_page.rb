module Stretched
  class ExtractJsonFromPage
    include Interactor

    attr_accessor :instance

    def setup
      Extension.register_all
      context[:adapter] ||= ObjectAdapter.find(context[:adapter_name])
    end

    def perform
      context[:json_objects] = page.doc.xpath(adapter.xpath).map do |node|
        instance = Hashie::Mash.new
        instance = run_json_setters(instance, node)
        instance = run_ruby_setters(instance, node)
        instance.select { |attribute, value| adapter.validate(attribute, value) }
        instance
      end
    end

    #
    # private
    #

    def run_json_setters(instance, node)
      runner = Script.runner
      runner.set_context(doc: node, page: page, browser_session: context[:browser_session])
      read_with_json(
        runner: runner,
        instance: instance
      )
    end

    def run_ruby_setters(instance, node)
      return instance unless adapter.scripts
      adapter.scripts.each do |script_name|
        runner = Script.runner(script_name)
        runner.set_context(doc: node, page: page, browser_session: context[:browser_session])
        instance = read_with_script(
          runner: runner,
          instance: instance
        )
      end
      instance
    end

    def read_with_json(opts)
      runner, instance = opts[:runner], opts[:instance]
      adapter.attribute_setters.each do |attribute_name, setters|
        raise "Property #{attribute_name} is not defined in schema #{adapter.schema_key}" unless adapter.validate_property(attribute_name)
        setters.detect do |setter|
          if setter.is_a?(Hash)
            method = setter.reject {|k,v| k == "filters"}.first.first
            args = setter[method]
            result = args.nil? ? runner.send(method) : runner.send(method, args)
          else
            result = runner.send(setter)
          end
          result = runner.filters(result, setter["filters"]) if setter["filters"]
          next unless result = clean_up(result)
          instance[attribute_name] = result
        end
      end

      instance
    end

    def read_with_script(opts)
      runner, instance = opts[:runner], opts[:instance]
      runner.attributes.each do |attribute_name, value|
        raise "Undefined property #{attribute_name} in schema #{adapter.schema_key}" unless adapter.validate_property(attribute_name)
        result = value.is_a?(Proc) ? value.call(instance) : value
        instance[attribute_name.to_s] = result
      end

      instance
    end

    def clean_up(result)
      return unless result.is_a?(String) && result = Sanitize.clean(result, elements: [])
      result = HTMLEntities.new.decode(result)
      result = result.strip.squeeze(" ") rescue nil
      result.present? ? result : nil
    end
  end
end
