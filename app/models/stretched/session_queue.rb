module Stretched
  class SessionQueue < ObjectQueue


    def initialize(name)
      super
      @set_name = "#session-queue::#{name}"
    end

    def pop
      if object = super
        Session.new(object)
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
