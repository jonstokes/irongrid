module Stretched
  class RateLimit < Registration

    %w(peak off_peak timezone).each do |key|
      define_method key do
        @data[key] if @data
      end
    end

    attr_reader :limiter
    delegate :with_limit, to: :limiter

    def initialize(opts)
      super(opts.merge(type: "RateLimit"))
      @limiter = Stretched::RateLimiter.new(seconds_per_action)
    end

    def seconds_per_action
      return 5 unless @data
      time_slots.each do |time_slot, attr|
        start_time = ActiveSupport::TimeZone[timezone].parse(attr["start"])
        duration = attr["duration"].to_i.hours
        end_time = (start_time + duration).in_time_zone(timezone)
        return attr["rate"] if (start_time..end_time).cover?(ActiveSupport::TimeZone[timezone].now)
      end
      return peak["rate"]
    end

    def time_slots
      @data.select { |k, v| %w(peak off_peak).include?(k) }
    end
  end
end
