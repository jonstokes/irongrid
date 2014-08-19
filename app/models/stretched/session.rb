module Stretched
  class Session
    attr_reader :session_definition, :object_adapters, :queue_name, :urls, :start_time, :key

    delegate :with_limit, :page_format, to: :session_definition

    SESSION_PROPERTIES = %w(queue session_definition object_adapters urls key)

    def initialize(opts)
      Session.validate(opts)
      opts.symbolize_keys!
      @key = opts[:key]
      @queue_name = opts[:queue]
      @session_definition = Stretched::SessionDefinition.find_or_create(opts[:session_definition])
      @object_adapters = opts[:object_adapters].map do |obj|
        Stretched::ObjectAdapter.find_or_create(obj)
      end
      @urls = opts[:urls].map { |feed| expand_links(feed) }.flatten.uniq
    end

    def definition_key; session_definition.key; end
    def size; urls.count; end
    alias count size

    def start!
      @start_time = Time.now.utc
    end

    def self.create(opts)
      q = SessionQueue.find_or_create(opts[:queue])
      q.add opts
    end

    def self.validate(object)
      object.each do |key, value|
        raise "Invalid session property #{key}" unless SESSION_PROPERTIES.include?(key.to_s)
      end
    end

    private

    def expand_links(feed)
      feed.symbolize_keys!
      return feed[:url] unless feed[:start_at_page]
      (feed[:start_at_page]..feed[:stop_at_page]).step(feed[:step] || 1).map do |page_number|
        feed[:url].sub("PAGENUM", page_number.to_s)
      end
    end

  end
end
