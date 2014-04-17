module SearchAlertQueues
  class AlertQueue
    MAX_QUEUE_SIZE = 30

    include Retryable

    attr_reader :listing_id, :percolator_name

    def initialize(percolator_name)
      @percolator_name = percolator_name
    end

    def percolator_key
      "listings:#{percolator_name}"
    end

    def utc_timestamp
      Time.now.utc.to_i
    end

    def push(listing_id)
      shift while full?
      with_redis do |conn|
        stamp = utc_timestamp
        puts "Adding (#{stamp}, #{listing_id})"
        conn.zadd(percolator_key, utc_timestamp, listing_id)
      end
    end

    def full?
      size >= MAX_QUEUE_SIZE
    end

    def shift
      with_redis do |conn|
        items = conn.zrange(percolator_key, 0, 0)
        conn.zremrangebyrank(percolator_key, 0, 0)
        items.first.try(:to_i)
      end
    end

    def size
      with_redis do |conn|
        conn.zcard(percolator_key)
      end
    end

    private

    def with_redis(&block)
      retryable(sleep: 0.5) do
        IRONSIGHTS_REDIS_POOL.with &block
      end
    end
  end

  def add(opts)
    AlertQueue.new(opts[:percolator_name]).push(opts[:listing_id))
  end
end
