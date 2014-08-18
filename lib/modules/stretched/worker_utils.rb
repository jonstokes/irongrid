module Stretched
  module WorkerUtils
    def _workers
      workers_for_class("#{self.name}")
    end

    def _jobs
      jobs_for_class("#{self.name}")
    end

    def active_workers
      _workers.map do |w|
        {
          :session_queue => worker_session_queue(w),
          :jid => worker_jid(w),
          :time => worker_time(w)
        }
      end
    end

    def queued_jobs
      _jobs.map { |j| {:session_queue => job_session_queue(j), :jid => job_jid(j)} }
    end

    def workers_with_session_queue(session_queue)
      active_workers.select { |w| w[:session_queue] == session_queue }
    end

    def jobs_with_session_queue(session_queue)
      queued_jobs.select { |j| j[:session_queue] == session_queue }
    end

    def jobs_in_flight_with_session_queue(session_queue)
      jobs_with_session_queue(session_queue) + workers_with_session_queue(session_queue)
    end

    def workers
      Sidekiq::Workers.new.map do |process_id, thread_id, worker|
        worker
      end
    end

    def workers_for_queue(q)
      workers.select do |worker|
        worker_queue(worker) == q
      end
    end

    def workers_for_class(klass)
      workers.select do |worker|
        worker_class(worker) == klass
      end
    end

    def worker_jid(worker)
      worker["payload"]["jid"] if worker["payload"]
    end

    def worker_session_queue(worker)
      worker["payload"]["args"].first["queue"] if worker["payload"] && worker["payload"]["args"].try(:any?)
    end

    def worker_time(worker)
      worker["run_at"]
    end

    def worker_class(worker)
      worker["payload"]["class"] if worker["payload"]
    end

    def worker_queue(worker)
      worker["queue"]
    end

    def jobs_for_queue(q)
      Sidekiq::Queue.new(q)
    end

    def jobs_for_class(klass)
      queues.map do |q|
        jobs_for_queue(q).select { |job| job.klass == klass }
      end.flatten
    end

    def job_session_queue(job)
      job.args.first["queue"] if job.args.any?
    end

    def job_jid(job)
      job.jid
    end

    def number_of_active_workers(q_name)
      workers_for_queue(q_name).count
    end

    def queues
      unless Rails.env.test?
        Sidekiq::Stats.new.queues.keys.reject{ |q| q == "fast_db" }
      else
        Sidekiq::Stats.new.queues.keys
      end
    end

  end
end
