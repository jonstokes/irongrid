module Stretched
  class SessionDefinition < Registration

    attr_reader :page_format, :rate_limits

    delegate :with_limit, to: :rate_limits

    def initialize(opts)
      super(opts.merge(type: SessionDefinition))
      @page_format = opts[:page_format]
      @rate_limits = Stretched::Registration.find_or_create(opts[:rate_limits])
    end

  end
end
