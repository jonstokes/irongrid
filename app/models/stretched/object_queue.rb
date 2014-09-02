module Stretched
  class ObjectQueue
    include StretchedRedisPool
    include Stretched::Retryable

    attr_reader :set_name, :name

    def initialize(name)
      @name = name
      @set_name = "#{user}::object-queue::#{name}"
    end

    def push(objects)
      return 0 if objects.is_a?(Enumerable) && objects.empty?
      objects = [objects].flatten
      objects.each { |obj| obj.stringify_keys! if obj.respond_to?(:stringify_keys!) }
      add_objects_to_redis(objects)
    end

    def pop
      with_redis do |conn|
        if key = conn.spop(set_name)
          raise "ObjectQueue #{name}: missing key #{key} for user #{user}" unless data = conn.get(key)
          conn.del(key)
          self.class.value_from_redis(data).merge(key: key)
        end
      end
    end

    def rem(links)
      return 0 unless links
      return 0 if links.is_a?(String) && links.blank?

      if links.is_a?(Array)
        return 0 if links.empty?
        links = links.uniq.select(&:present?)
      else
        links = [links]
      end

      remove_keys_from_redis(links)
    end

    def clear
      with_redis do |conn|
        each_key do |key|
          conn.del(key)
        end
        conn.del(set_name)
      end
    end

    def empty?
      with_redis do |conn|
        return true unless conn.exists(set_name)
        conn.scard(set_name).zero?
      end
    end

    def each_key
      with_redis do |conn|
        conn.sscan_each(set_name) do |key|
          yield key
        end
      end
    end

    def each_message
      with_redis do |conn|
        conn.sscan_each(set_name) do |key|
          next unless value = conn.get(key)
          yield self.class.value_from_redis(value)
        end
      end
    end

    def members
      with_redis do |conn|
        conn.smembers(set_name)
      end
    end

    def all
      members.map do |key|
        ObjectQueue.get(key)
      end
    end

    def any?
      !empty?
    end

    def has_key?(key)
      with_redis do |conn|
        key.present? &&
          conn.exists(set_name) &&
          conn.sismember(set_name, key)
      end
    end

    def size
      with_redis do |conn|
        return 0 unless conn.exists(set_name)
        conn.scard(set_name)
      end
    end

    alias add push
    alias length size
    alias count size

    def user
      self.class.user
    end

    def self.find_or_create(name)
      new(name)
    end

    def self.get(key)
      return unless key.present? && (value = with_redis { |conn| conn.get(key) })
      value_from_redis(value)
    end

    def self.key(object)
      Digest::MD5.hexdigest(object.to_json)
    end

    def self.value_from_redis(value)
      Hashie::Mash.new JSON.parse(value)
    end

    def self.user
      Stretched::Settings.user
    end

    private

    def add_objects_to_redis(objects)
      objects.map do |obj|
        key = ObjectQueue.key(obj)
        next if with_redis { |conn| conn.sismember(set_name, key) }
        with_redis do |conn|
          conn.set(key, obj.to_json)
          conn.sadd(set_name, key)
        end
        key
      end.compact
    end

    def remove_keys_from_redis(keys)
      keys.each do |key|
        with_redis do |conn|
          conn.srem(set_name, key)
          conn.del(key)
        end
      end
      keys.count
    end

  end
end
