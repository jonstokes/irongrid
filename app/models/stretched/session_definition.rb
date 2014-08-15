module Stretched
  class SessionDefinition < Registration

    attr_reader :page_format, :rate_limits

    delegate :with_limit, to: :rate_limits

    def initialize(opts)
      super(opts.merge(type: "SessionDefinition"))
      @page_format = @data['page_format']
      @rate_limits = Stretched::RateLimit.find_or_create(@data['rate_limits'])
    end

  end
end
