module Stretched
  class SessionQueue < ObjectQueue
    attr_reader :name

    def initialize(name)
      super
      @name = name
      @set_name = "session-queue::#{name}"
    end

    def pop
      if object = super
        Session.new(object)
      end
    end

    def self.each
      with_redis do |conn|
        conn.scan_each(:match => "session-queue::") do |set|
          yield new(set)
        end
      end
    end

    private

    def validate_session_format(objects)
      objects.each { |o| Session.validate(o) }
    end

    def add_objects_to_redis(objects)
      validate_session_format(objects)
      super(objects)
    end

  end
end
