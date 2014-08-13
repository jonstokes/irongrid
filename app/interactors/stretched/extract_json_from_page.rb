module Stretched
  class ExtractJsonFromPage
    include Interactor

    attr_accessor :instance, :adapter

    def perform
      @adapter = ObjectAdapter.find(adapter_name)

      page.doc.xpath(adapter.xpath).map do |node|
        instance = read_with_json(Hash.new)
        adapter.scripts.each do |script_name|
          instance = read_with_script(script_name, instance)
        end

        instance
      end
    end

    #
    # private
    #

    def read_with_json(instance)
      runner = ScriptRunner.new
      runner.set_context(context)
      adapter.attribute_setters.each do |attribute_name, setters|
        setters.each do |setter|
          if setter.is_a?(Hash)
            method = setter.reject("filters").first
            args = setter[method]
            result = runner.send(method, args)
          else
            result = runner.send(setter)
          end
          result = runner.filters(result, setter["filters"]) if setter["filters"]
          instance[attribute_name] = result if adapter.validate(attribute_name, result)
        end
      end

      instance
    end

    def read_with_script(script_name, instance)
      runner = Script.runner(script_name)
      runner.set_context(context)
      runner.attributes.each do |attribute_name, value|
        result = value.is_a?(Proc) ? value.call(instance) : value
        instance[attribute_name] = result if adapter.validate(attribute_name, result)
      end

      instance
    end

  end
end
