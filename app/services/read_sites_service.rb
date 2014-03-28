class ReadSitesService < CoreService

  def active_workers
    workers_for_class("#{self.class}").map do |w| 
      {
        :domain => worker_domain(w), 
        :jid => worker_jid(w), 
        :host => worker_host(w),
        :time => worker_time(w)
      }
    end
  end

  def queued_jobs
    jobs_for_class("#{self.class}").map { |j| {:domain => job_domain(j), :jid => job_jid(j)} }
  end

  def should_add_job?(domain)
    !crawls.find { |c| c[:domain] == domain }
  end

end
