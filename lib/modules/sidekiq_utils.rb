module SidekiqUtils

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

  def worker_domain(worker)
    worker["payload"]["args"].first["domain"] if worker["payload"] && worker["args"].any?
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
    queues.reject{ |q| q == "fast_db" }.map do |q|
      jobs_for_queue(q).select { |job| job.klass == klass }
    end.flatten
  end

  def job_domain(job)
    job.args.first["domain"] if job.args.any?
  end

  def job_jid(job)
    job.jid
  end

  def number_of_active_workers(q_name)
    workers_for_queue(q_name).count
  end

  def queues
    Sidekiq::Stats.new.queues.keys
  end

  def clear_all_queues
    queues.each do |q|
      clear_queue(q)
    end
  end
end
