module Stretched
  class Script < Registration

    def initialize(opts)
      super(opts.merge(type: "Script"))
    end

    def register
      # NOTE: This returns a populated instance of ScriptRunner
      # that has all extensions defined on it and contains
      # Procs for the code defined in @data
      eval data
    end

    def self.runner(user, key = nil)
      return ScriptRunner.new unless key
      script = find(user, key)
      script.register
    end

    def self.load_file(filename)
      source = get_source(filename)
      key = source[/(script)\s+\".*?\"/].split(/(script) \"/).last.split(/\"/).last
      [Hashie::Mash.new(key: key, type: "Script" , data: source)]
    end

    def self.write_redis_format(data); data; end
    def self.read_redis_format(data); data; end

    def self.define(&block)
      definition_proxy = DefinitionProxy.new
      definition_proxy.instance_eval(&block)
    end

  end
end
