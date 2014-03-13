module Retryable
  # Options:
  # * :tries - Number of retries to perform. Defaults to 1.
  # * :on - The Exception on which a retry will be performed. Defaults to Exception, which retries on any Exception.
  #
  # Example
  # =======
  #   retryable(:tries => 1, :on => OpenURI::HTTPError) do
  #     # your code here
  #   end
  #

  def retryable(options = {}, &block)
    opts = { :tries => 5, :on => Exception, :sleep => 1 }.merge(options)

    retry_exception, retries, interval = opts[:on], opts[:tries], opts[:sleep]

    begin
      return yield
    rescue retry_exception
      sleep interval
      retry if (retries -= 1) > 0
    end
    yield
  end

  def retryable_with_success(options = {}, &block)
    opts = { :tries => 5, :on => Exception, :sleep => 1 }.merge(options)
    retry_exception, retries, interval = opts[:on], opts[:tries], opts[:sleep]
    success = false
    begin
      yield
      success = true
    rescue retry_exception
      sleep interval
      retry if (retries -= 1) > 0
    end
    success
  end

  def retryable_with_aws(options = {}, &block)
    opts = { :tries => 10, :on => Exception, :sleep => 1 }.merge(options)

    retry_exception, retries, interval = opts[:on], opts[:tries], opts[:sleep]

    begin
      return yield
    rescue OpenSSL::SSL::SSLError, Timeout::Error
      sleep interval
      aws_connect!
      retry unless (retries -= 1).zero?
    rescue retry_exception
      sleep interval
      retry unless (retries -= 1).zero?
    end
    yield
  end

  def self.included(klass)
    klass.extend ClassMethods
  end

  module ClassMethods
    def retryable_with_connection
      retval = nil
      begin
        tries ||= 10
        ActiveRecord::Base.connection_pool.with_connection { retval = yield }
        return retval
      rescue ActiveRecord::JDBCError, ActiveRecord::StatementInvalid => e
        ActiveRecord::Base.connection_pool.clear_stale_cached_connections!
        if e.message =~ /This connection has been closed/
          ActiveRecord::Base.connection.reconnect!
        end
        sleep 1
        retry unless (tries -= 1).zero?
      rescue Exception
        sleep 1
        retry unless (tries -= 1).zero?
      end
      yield
    end
  end


end
