module SearchAlertQueues
  class AlertQueue
    MAX_QUEUE_SIZE = 30

    include Bellbro::Retryable
    include Bellbro::Pool

    attr_reader :listing_id, :percolator_name

    pool :ironsights_redis_pool

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
      with_connection do |conn|
        conn.zadd(percolator_key, utc_timestamp, listing_id)
      end
    end

    def full?
      size >= MAX_QUEUE_SIZE
    end

    def shift
      with_connection do |conn|
        items = conn.zrange(percolator_key, 0, 0)
        conn.zremrangebyrank(percolator_key, 0, 0)
        items.first.try(:to_i)
      end
    end

    def size
      with_connection do |conn|
        conn.zcard(percolator_key)
      end
    end
  end

  def self.push(opts)
    AlertQueue.new(opts[:percolator_name]).push(opts[:current_listing_id])
  end
end
