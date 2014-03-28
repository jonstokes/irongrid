module SidekiqUtils

  def workers
    Sidekiq.redis do |conn|
      conn.smembers('workers').map do |w|
        msg = conn.get("worker:#{w}")
        msg ? [w, Sidekiq.load_json(msg)] : nil
      end.compact.sort { |x| x[1] ? -1 : 1 }
    end
  end

  def workers_for_queue(q)
    workers.select do |worker|
      worker.last["queue"] == q
    end
  end

  def workers_for_class(wclass)
    workers.select do |worker|
      worker_class(worker) == wclass
    end
  end

  def clear_workers_for_class(wclass)
    Sidekiq.redis do |conn|
      workers_for_class(wclass).each do |w|
        conn.del("worker:#{w}")
        conn.srem("workers", w)
      end
    end
  end

  def worker_bid(worker)
    worker.last["payload"]["bid"]
  end

  def worker_jid(worker)
    worker.last["payload"]["jid"]
  end

  def worker_domain(worker)
    worker.last["payload"]["args"].first["domain"] if worker.last["payload"]["args"].any?
  end

  def worker_time(worker)
    worker.last["run_at"]
  end

  def worker_host(worker)
    return nil unless worker && worker.first
    return worker.first.split(":").first
  end

  def worker_class(worker)
    worker.last["payload"]["class"]
  end

  def jobs_for_queue(q)
    Sidekiq.redis do |conn|
      conn.lrange("queue:#{q}", 0, (conn.llen("queue:#{q}") - 1)).map do |job|
        Sidekiq.load_json(job)
      end
    end
  end

  def jobs_for_class(jclass)
    queues.map do |q|
      jobs_for_queue(q).select { |job| job["class"] == jclass }
    end.flatten
  end

  def job_domain(job)
    job["args"].first["domain"] if job["args"].any?
  end

  def job_bid(job)
    job["bid"]
  end

  def job_jid(job)
    job["jid"]
  end

  def pending_work?(q)
    !empty_queue?(q)
  end

  def number_of_active_workers(q_name)
    workers_for_queue(q_name).count
  end

  def queues
    Sidekiq.redis { |conn| conn.smembers('queues') }
  end

  def scalable?(q)
    SCALABLE_QUEUES.include?(q)
  end

  def empty_queue?(name)
    Sidekiq.redis { |conn| conn.llen("queue:#{name}") == 0 }
  end

  def queue_size(name)
    Sidekiq.redis { |conn| conn.llen("queue:#{name}") }
  end

  def clear_all_queues
    queues.each do |q|
      clear_queue(q)
    end
  end

  def clear_queue(name)
    Sidekiq.redis do |conn|
      conn.llen("queue:#{name}").times do
        conn.lpop("queue:#{name}")
      end
    end
  end

  def any_active_queues?
    queues.detect { |q| active?(q) }
  end

  def active?(q)
    (scalable?(q) && (queue_size(q) + number_of_active_workers(q) + dedicated_processors(q) + servers[q].size > 0)) || (!scalable?(q) && (queue_size(q) + number_of_active_workers(q) > 0))
  end

  def processors_per_server_for(queue)
    YAML.load(File.read(File.join('config', 'sidekiq_queues.yml')))[Rails.env][queue]['processors_per_server']
  end

  def maximum_instances_for(queue)
    YAML.load(File.read(File.join('config', 'sidekiq_queues.yml')))[Rails.env][queue]['max_live_instances']
  end

  def aws_options
    aws_config = YAML.load(File.read(File.join('config', 'aws.yml')))[Rails.env]
    {
      :provider => 'AWS', 
      :aws_access_key_id => aws_config['access_key_id'], 
      :aws_secret_access_key => aws_config['secret_access_key']
    }
  end
end
