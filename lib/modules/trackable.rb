module Trackable
  include Notifier
  attr_reader :record

  def track(opts={})
    @log_record_schema = self.class::LOG_RECORD_SCHEMA
    opts.symbolize_keys!
    @write_interval = opts[:write_interval] || 50
    opts.delete(:write_interval)
    @count = 0
    validate(opts)
    initialize_log_record(opts)
    status_update(true)
  end

  def status_update(force = false)
    return unless force || ((@count += 1) % @write_interval) == 0
    LogRecordWorker.perform_async(@record)
    initialize_log_record
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
    status_update(true)
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

  def initialize_log_record(opts={})
    @record ||= {}
    @record[:data] ||= {}
    data = {}

    self.class::LOG_RECORD_SCHEMA.each do |k, v|
      if v == Integer
        data[k] = 0
      else
        data[k] = v.new
      end
    end

    data.merge!(opts)
    data.merge!(domain: @domain, complete: false)

    @record.merge!(
      jid:   self.jid,
      agent: "#{self.class}",
      archived: false
    )
    @record[:data].merge!(data)
  end
end
