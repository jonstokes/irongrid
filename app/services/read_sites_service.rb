class ReadSitesService < CoreService
  SLEEP_INTERVAL = Rails.env.test? ? 0.1 : 30

  def each_job
    Site.each do |site|
      next unless should_add_job?(site)
      yield(klass: "PopulateSessionQueueWorker", arguments: {domain: site.domain})
    end
  end

  def should_add_job?(site)
    site.should_read? &&
      PopulateSessionQueueWorker.jobs_in_flight_with_domain(site.domain).empty? &&
      PopulateSessionQueueWorker.should_run?(site)
  end
end
