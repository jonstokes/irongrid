class Stretched::SessionQueueService < CoreService
  include Stretched::WorkerUtils

  SLEEP_INTERVAL = Rails.env.test? ? 1 : 15


  def initialize
    @done = false
    @jid = Digest::MD5.hexdigest(Time.now.utc.to_s + Thread.current.object_id.to_s)
  end

  def start
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
    CoreService.mutex.synchronize { track }
    begin
      puts "[#{Time.now.utc}] #{self.class} starting #{jobs.count} jobs..." if jobs.any?
      start_jobs
      CoreService.mutex.synchronize { status_update }
      sleep self.class::SLEEP_INTERVAL
    end until @done
    CoreService.mutex.synchronize { stop_tracking }
  end

  def start_jobs
    mutex.synchronize {
      SessionQueue.each do |q|
        next unless should_add_job?(q)
        jid = RunSessionsWorker.perform_async(queue: q.name)
        notify "Starting job #{jid} RunSessionsWorker for session queue #{q.name} of size #{q.size}."
      end
    }
  end


  def should_add_job?(q)
    jobs_in_flight_with_session_queue(q.name).empty?
  end


  def self.mutex
    $mutex ||= Mutex.new
  end

end
