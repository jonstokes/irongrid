class ReadSitesService < CoreService
  SLEEP_INTERVAL = Rails.env.test? ? 0.1 : 30

  def jobs
    Site.all.map do |site|
      next unless should_add_job?(site)
      { klass: "PopulateSessionQueueWorker", arguments: {domain: site.domain} }
    end.compact
  end

  def should_add_job?(site)
    site.should_read? &&
      PopulateSessionQueueWorker.jobs_in_flight_with_domain(site.domain).empty? &&
      PopulateSessionQueueWorker.should_run?(site.domain)
  end
end
