class CoreWorker < CoreModel
  include Sidekiq::Worker
  include Trackable
  include SidekiqUtils

  def perform(opts)
    # override
  end

  def jobs_with_domain(domain)
    # self.class.jobs.select {  }
  end

  def workers_with_domain(domain)
    # self.class.workers.select {  }
  end

  def jobs_in_flight_with_domain(domain)
    jobs_with_domain(domain) + workers_with_domain(domain)
  end
end
