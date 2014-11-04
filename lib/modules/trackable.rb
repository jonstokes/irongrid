module Trackable
  include Notifier
  attr_reader :record

  def track(opts={})
    return if @log_record_schema # Ignore repeated calls to #track, as in RefreshLinksWorker
    opts.symbolize_keys!
    @log_record_schema = self.class::LOG_RECORD_SCHEMA
    @record = { data: {} }
    @write_interval = opts[:write_interval] || 500
    @count = 0
    @tracking = true
    status_update(true)
  end

  def status_update(force = false)
    return unless force || ((@count += 1) % @write_interval) == 0
    notify("#{@record.to_param}")
  end

  def record_set(attr, value)
    attr = attr.to_sym
    validate(attr => value)
    @record[:data][attr] = value
  end

  def record_incr(attr)
    attr = attr.to_sym
    validate(attr => 1)
    @record[:data][attr] += 1
  end

  def stop_tracking
    @record[:data][:complete] = true
    @tracking = false
    status_update(true)
  end

  def tracking?
    !!@tracking
  end

  private
  def log_record_attributes
    @log_record_schema.keys + [:jid, :agent, :archived]
  end

  def validate(attrs)
    attrs.each do |attr, value|
      raise "Invalid attribute #{attr}" unless log_record_attributes.include?(attr)
      raise "Invalid type for #{attr}" unless [value.class, value.class.superclass].include?(self.class::LOG_RECORD_SCHEMA[attr])
    end
  end

end
