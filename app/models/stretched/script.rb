module Stretched
  class Script < Registration

    def initialize(opts)
      super(opts.merge(type: "Script"))
    end

    def register
      eval data
    end

    def self.register_all
      keys.each do |key|
        next if registry[key]
        script = find(key)
        script.register
      end
    end

    def self.runner(key)
      return registry[key] if registry[key] # Cuts down on redis pool usage
      script = find(key)
      script.register
      registry[script.key]
    end

    def self.load_file(filename)
      source = get_source(filename)
      key = source[/(script)\s+\".*?\"/].split(/(script) \"/).last.split(/\"/).last
      [Hashie::Mash.new(key: key, type: "Script" , data: source)]
    end

    def self.write_redis_format(data); data; end
    def self.read_redis_format(data); data; end

    def self.registry
      @registry ||= ThreadSafe::Cache.new
    end

    def self.register(script_name, runner)
      @registry ||= ThreadSafe::Cache.new
      @registry[script_name.to_s] = runner
    end

    def self.define(&block)
      definition_proxy = DefinitionProxy.new
      definition_proxy.instance_eval(&block)
    end

  end
end
