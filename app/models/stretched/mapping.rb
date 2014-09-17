module Stretched
  class Mapping < Registration

    def initialize(opts)
      super(opts.merge(type: "Mapping"))
    end

    def map(text)
      @data.detect do |k, v|
        next unless v
        !!v.detect { |str| str == text }
      end.try(:first)
    end

    def terms; @data.keys; end
    def [](term); @data[term.to_s]; end
  end
end
