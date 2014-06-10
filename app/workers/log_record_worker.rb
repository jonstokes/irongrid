class LogRecordWorker < CoreWorker
  include ConnectionWrapper

  sidekiq_options queue: :fast_db, retry: true

  def perform(record)
    retries = 5
    record.symbolize_keys!
    if lr = db { LogRecord.find_by_jid(record[:jid]) }
      lr.unarchive if lr.archived?
      update_record(lr, record)
    else
      db { LogRecord.create(record) }
    end
  rescue ActiveRecord::RecordNotUnique, ActiveRecord::JDBCError
    notify "Log record is not unique: #{record}"
    return
  end

  def update_record(lr, record)
    record.stringify_keys!
    record["data"].stringify_keys!

    lr.data.each do |k, v|
      if v.is_a?(Integer)
        record["data"][k] ||= 0
        record["data"][k] = lr.data[k] + record["data"][k]
      elsif v.is_a?(Array)
        record[:data][k] ||= []
        record["data"][k] = lr.data[k] + record["data"][k]
      elsif v.is_a?(Hash)
        record["data"][k] ||= {}
        record["data"][k] = lr.data[k].merge(record["data"][k])
      end
    end

    lr.data_will_change!
    db { lr.update(record) }
  end
end
