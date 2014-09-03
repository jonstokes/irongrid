module Stretched
  class RunSessionsService
    include Stretched::WorkerUtils
    include Stretched::Notifier

    SLEEP_INTERVAL = Rails.env.test? ? 1 : 15


    def initialize
      @done = false
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
      begin
        start_jobs
        sleep self.class::SLEEP_INTERVAL
      end until @done
    end

    def start_jobs
      RunSessionsService.mutex.synchronize {
        SessionQueue.each do |q|
          next unless should_add_job?(q)
          puts "Adding RunSessionsWorker job for queue #{q.name}"
          jid = RunSessionsWorker.perform_async(queue: q.name)
          puts "Starting job #{jid} RunSessionsWorker for session queue #{q.name} of size #{q.size}."
        end
      }
    end


    def should_add_job?(q)
      RunSessionsWorker.jobs_in_flight_with_session_queue(q.name).empty?
    end


    def self.mutex
      $mutex ||= Mutex.new
    end

  end
end
