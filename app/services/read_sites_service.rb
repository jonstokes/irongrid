class ReadSitesService < CoreService

  def jobs
    Site.active.map do |site|
      next unless should_add_job?(site)
      { klass: site.read_with, arguments: {domain: site.domain} }
    end.compact
  end

  def should_add_job?(site)
    site.should_read? && !any_read_jobs_in_flight_with_domain?(site.domain)
  end

  def any_read_jobs_in_flight_with_domain?(domain)
    %w(CreateLinksWorker ScrapePagesWorker).detect do |class_name|
      klass = Object.const_get class_name
      klass.jobs_in_flight_with_domain(domain).any?
    end
  end
end
