module Stretched
  class RateLimit < Registration

    %w(peak off_peak).each do |key|
      define_method key do
        @data[key] if @data
      end
    end

    def initialize(opts)
      super(opts.merge(type: "RateLimit"))
    end

    def self.find(key)
      super(type: "RateLimit", key: key)
    end
  end
end
