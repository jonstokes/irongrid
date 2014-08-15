module Stretched
  class SessionQueue < ObjectQueue

    SESSION_PROPERTIES = %w(queue session_definition object_adapters urls)

    def initialize(name)
      super
      @set_name = "#session-queue::#{name}"
    end

    def pop
      Session.new(super)
    end

    private

    def validate_session_format(objects)
      objects.each do |object|
        object.each do |key, value|
          raise "Invalid session property #{key}" unless SESSION_PROPERTIES.include?(key)
        end
      end
    end

    def add_objects_to_redis(objects)
      validate_session_format(objects)
      super(objects)
    end

  end
end
