module Stretched
  class ObjectQueue < CoreModel
    include IrongridRedisPool

    attr_reader :set_name, :name

    def initialize(name)
      @name = name
      @set_name = "#object-queue::#{name}"
    end

    def push(objects)
      return 0 if objects.empty?
      objects = [objects] unless objects.is_a?(Array)
      add_objects_to_redis(objects)
    end

    def pop
      with_redis do |conn|
        if key = conn.spop(set_name)
          raise "ObjectQueue: missing key #{key}" unless data = conn.get(key)
          conn.del(key)
          JSON.parse(key)
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
          if value = conn.get(key)
            yield JSON.parse(value)
          else
            notify "TROUBLESHOOT: Missing content for key #{key}"
          end
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

    def self.find_or_create(name)
      new(name)
    end

    #
    # This is cheating on the queue abstraction, but it
    # makes specs and pruning links easier
    #
    def self.get(key)
      return unless key.present? && (value = with_redis { |conn| conn.get(key) })
      JSON.parse(value)
    end

    private

    def add_objects_to_redis(objects)
      count = 0
      objects.each do |obj|
        key = Digest::MD5.hexdigest(obj.to_yaml)
        next if with_redis { |conn| conn.sismember(set_name, key) }
        with_redis do |conn|
          conn.set(key, obj.to_json)
          conn.sadd(set_name, key)
        end
        count += 1
      end
      count
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
