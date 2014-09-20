module Stretched
  class SessionQueue < ObjectQueue
    attr_reader :name, :user

    def initialize(user, name)
      super
      @name = name
      @user = user
      @set_name = "session-queue::#{user}::#{name}"
    end

    def pop
      if object = super
        Session.new(user, object)
      end
    end

    def self.each_for_user(user)
      with_redis do |conn|
        conn.scan_each(:match => "session-queue::#{user}::*") do |set|
          q = set.split("::").last
          yield new(user, q)
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
