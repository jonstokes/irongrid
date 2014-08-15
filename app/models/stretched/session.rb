module Stretched
  class Session
    attr_reader :session_definition, :urls, :object_adapters, :queue_name

    delegate :with_limit, :page_format, to: :session_definition

    def initialize(opts)
      @queue_name = opts[:queue]
      @session_definition = Stretched::Registration.find_or_create(opts[:session_definition], SessionDefinition)
      @object_adapters = opts[:object_adapters].map do |obj|
        Stretched::Registration.find_or_create(obj, ObjectAdapter)
      end
      @urls = opts[:urls]
    end

    def use_phantomjs?
      page_format == "dhtml"
    end

    def definition_key; session_definition.key; end
    def size; urls.count; end
    alias count size

    def self.create(opts)
      q = SessionQueue.find_or_create(opts[:queue])
      q.add opts
    end
  end
end
