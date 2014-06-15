class CoreWorker < CoreModel
  include Sidekiq::Worker
  extend SidekiqUtils

  def init(opts)
    # override
  end

  def perform(opts)
    # override
  end

  def clean_up
    # override
  end

  def transition
    # override
  end

  def i_am_alone_with_this_domain?
    self.class.jobs_with_domain(@domain).select { |j| jid != j[:jid] }.empty? &&
      self.class.workers_with_domain(@domain).select { |j| jid != j[:jid] }.empty?
  end

  def self._workers
    workers_for_class("#{self.name}")
  end

  def self._jobs
    jobs_for_class("#{self.name}")
  end

  def self.active_workers
    _workers.map do |w|
      {
        :domain => worker_domain(w),
        :jid => worker_jid(w),
        :time => worker_time(w)
      }
    end
  end

  def self.queued_jobs
    _jobs.map { |j| {:domain => job_domain(j), :jid => job_jid(j)} }
  end

  def self.workers_with_domain(domain)
    active_workers.select { |w| w[:domain] == domain }
  end

  def self.jobs_with_domain(domain)
    queued_jobs.select { |j| j[:domain] == domain }
  end

  def self.jobs_in_flight_with_domain(domain)
    jobs_with_domain(domain) + workers_with_domain(domain)
  end
end
