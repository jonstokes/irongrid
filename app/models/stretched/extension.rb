module Stretched
  class Extension < Script

    def initialize(opts)
      super(opts.merge(type: "Extension"))
    end

    def register
      eval data
    end

    def self.load_file(filename)
      source = get_source(filename)
      key = source[/(extension)\s+\".*?\"/].split(/(extension) \"/).last.split(/\"/).last
      [Hashie::Mash.new(key: key, type: "Extension" , data: source)]
    end

    def self.register(script_name, &block)
      @registry ||= ThreadSafe::Cache.new
      @registry[script_name.to_s] = block
    end
  end
end
