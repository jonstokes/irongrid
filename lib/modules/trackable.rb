module Trackable
  include Notifier
  attr_reader :tracker_error, :done, :record, :status

  def track(opts={})
    @done = false
    @status = {}
    @count = 0
    opts.merge!(
      domain:   @domain,
      worker:   "#{self.class}",
      complete: false
    )
    @write_interval = opts[:write_interval]
    @record ||= JobRecord.new(opts)
    status_update
  end

  def record_set(attr, value)
    @record.send("#{attr}=", value)
  end

  def status_update
    return if @write_interval && !(@count % @write_interval == 0)
    @count += 1
    notify @record.to_json
  end

  def record_incr(attr)
    @record.send("#{attr}=", @record.send(attr) + 1)
  end

  def stop_tracking
    @done = true
    @record.complete = true
    status_update
  end
end
