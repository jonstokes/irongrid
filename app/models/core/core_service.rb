class CoreService < CoreModel
  include SidekiqUtils
  include Trackable

  SLEEP_INTERVAL = Rails.env.test? ? 1 : 3600
  LOG_RECORD_SCHEMA = { jobs_started: Integer }

  attr_reader :thread, :thread_error, :jid

  def initialize
    @done = false
    @jid = Digest::MD5.hexdigest(Time.now.utc.to_s + Thread.current.object_id.to_s)
  end

  def start
    @mutex = Mutex.new
    @thread = Thread.new do
      begin
        run
      rescue Exception => @thread_error
        Airbrake.notify(@thread_error)
        ActiveRecord::Base.connection.close
        raise @thread_error
      end
    end
  end

  def stop
    @done = true
    notify "Stopping #{self.class} service..."
    @thread.join
    notify "#{self.class.to_s.capitalize} service stopped."
  end

  def run
    notify "Starting #{self.class} service."
    @mutex.synchronize { track }
    begin
      start_jobs
      @mutex.synchronize { status_update }
      sleep SLEEP_INTERVAL
    end until @done
    @mutex.synchronize { stop_tracking }
  end

  def start_jobs
    @mutex.synchronize {
      jobs.each do |job|
        klass = Object.const_get job[:klass]
        jid = klass.perform_async(job[:arguments])
        notify "Starting job #{jid} #{job[:klass]} with #{job[:arguments]}."
        record_incr(:jobs_started)
      end
    }
  end

  def jobs
    # Override
    []
  end

  def running?
    !@done
  end
end

