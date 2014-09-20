module Stretched
  class User
    include StretchedRedisPool
    include Stretched::Retryable

    attr_reader :name

    TABLE = "users"

    def initialize(name)
      @name = name
    end

    def save
      with_redis do |conn|
        conn.sadd TABLE, name
      end
    end

    def destroy
      with_redis do |conn|
        conn.srem TABLE, name
      end
    end

    def self.has_user?(name)
      with_redis do |conn|
        conn.sismember(TABLE, name)
      end
    end

    def self.each
      with_redis do |conn|
        conn.sscan_each(TABLE) do |name|
          yield new(name)
        end
      end
    end

  end
end
