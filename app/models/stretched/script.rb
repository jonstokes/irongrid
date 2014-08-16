module Stretched
  class Script < Registration

    def initialize(opts)
      super(opts.merge(type: "Script"))
    end

    def register_runner
      eval data
    end

    def self.runner(key)
      return registry[key] if registry[key] # Cuts down on redis pool usage
      script = find(key)
      script.register_runner
      registry[script.key]
    end

    def self.load_file(filename)
      source = get_source(filename)
      key = source[/script\s+\".*?\"/].split(/script \"/).last.split(/\"/).last
      [Hashie::Mash.new(key: key, type: "Script" , data: source)]
    end

    def self.write_redis_format(data); data; end
    def self.read_redis_format(data); data; end

    def self.convert_find_opts(opts)
      opts
    end

    def self.create(opts)
      super(opts.merge(type: "Script"))
    end

    def self.find(key)
      super(type: "Script", key: key)
    end

    def self.registry
      @registry ||= ThreadSafe::Cache.new
    end

    def self.register(script_name, runner)
      @registry ||= ThreadSafe::Cache.new
      @registry[script_name] = runner
    end

    def self.define(&block)
      definition_proxy = DefinitionProxy.new
      definition_proxy.instance_eval(&block)
    end

  end
end
