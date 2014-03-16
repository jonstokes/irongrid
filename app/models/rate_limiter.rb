class RateLimiter
  def initialize(actions_per_second=1)
    @aps = @interval = actions_per_second
    @samples = []
    @last_poll = Time.now - @interval
  end

  def with_limit
    @samples << Time.now - @last_poll
    @samples.shift if (@samples.size > 50)
    @last_poll = Time.now
    retval = yield
    if (@aps - average)  > 0
      @interval += @aps - average
    elsif (@aps - average) < 0
      @interval -= average - @aps
      @interval = 0 if @interval < 0
    end
    sleep @interval
    return retval
  end

  private
  def average
    @samples.inject(0.0) { |sum, el| sum + el } / @samples.size
  end
end
