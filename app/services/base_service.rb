class BaseService < Bellbro::Service
  poll_interval 60
  track_with_schema jobs_started: Integer
  worker_class BaseWorker

  def each_job
    IronCore::Site.each do |site|
      next unless should_add_job?(site)
      yield(domain: site.domain)
    end
  end

  def should_add_job?(site)
    worker_class.should_run?(site) &&
      worker_class.jobs_in_flight_with_domain(site.domain).empty?
  end
end
