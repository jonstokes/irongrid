class RateLimiter
  attr_reader :limit, :time_of_last_action

  def initialize(seconds_per_action = 1)
    @limit = seconds_per_action
    @time_of_last_action = Time.now
  end

  def with_limit
    wait
    yield
  end

  def wait
    while limit_exceeded? do
      sleep (limit / 2)
    end
    @time_of_last_action = Time.now
  end

  def limit_exceeded?
    Time.now - time_of_last_action < limit
  end
end
