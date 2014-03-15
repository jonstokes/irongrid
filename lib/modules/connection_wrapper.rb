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

  def check_out(tags)
    return if Rails.env.test?
    @connection_logger ||= ConnectionWrapper::Logger.new("#{self.class}(#{Thread.current.object_id})")
    @connection_logger.check_out(tags)
  end

  def check_in
    return if @connection_logger.nil? || Rails.env.test?
    @connection_logger.check_in
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

  class Logger
    include Retryable
    def initialize(agent)
      @agent = agent
      ddb = AWS::DynamoDB.new(AWS_CREDENTIALS)
      table_name = 'scoperrific-connection-logger'

      @table = ddb.tables[table_name]
      unless @table.exists?
        @table = ddb.tables.create(table_name, 10, 10, :hash_key => {:id => :string})
        sleep 5 while @table.status == :creating
      end
      @table.load_schema
    end

    def check_out(tags)
      token = ('a'..'z').to_a.shuffle[0,8].join
      row = { id: @agent, time_in: Time.now.to_s, token: token }
      if tags.try(:any?)
        tags.each { |k, v| tags[k] = v.to_s }
        row.merge!(tags)
      end
      retryable { @table.items.put(row) }
    end

    def check_in
      retryable do
        @table.items[@agent].try(:delete)
      end
    end

    def clear
      @table.items.each do |item|
        item.delete
      end
    end
  end

end
