module ConnectionWrapper

  def db_save
    db { self.save }
  end

  def db_save!
    db { self.save! }
  end

  def db_destroy
    db { self.destroy }
  end

  def db_update_attribute(attr, value)
    db { self.update(attr, value) }
  end

  def incr(name)
    value = self.send(name)
    self.update_attribute(name, value + 1)
  end

  def db(&block)
    ActiveRecord::Base.connection_pool.with_connection &block
  end

  def retryable_with_connection(&block)
    retval = nil
    begin
      tries ||= 5
      retval = db { yield }
    rescue ActiveRecord::JDBCError, ActiveRecord::StatementInvalid => e
      ActiveRecord::Base.connection_pool.clear_stale_cached_connections!
      if e.message =~ /This connection has been closed/
        ActiveRecord::Base.connection.reconnect!
      end
      sleep 1
      retry unless (tries -= 1).zero?
      ActiveRecord::Base.connection.close
      raise e
    rescue Exception => e
      sleep 1
      retry unless (tries -= 1).zero?
      ActiveRecord::Base.connection.close
      raise e
    end
    retval
  end

  def self.included(klass)
    klass.extend ClassMethods
  end

  module ClassMethods
    def db(&block)
      ActiveRecord::Base.connection_pool.with_connection &block
    end

    def db_create(attributes=nil, options = {}, &block)
      db { create(attributes, options, &block) }
    end
  end
end
