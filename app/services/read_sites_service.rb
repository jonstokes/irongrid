class ReadSitesService < CoreService
  SLEEP_INTERVAL = Rails.env.test? ? 0.1 : 60

  def each_job
    Site.each do |site|
      next unless should_add_job?(site)
      yield(klass: "PopulateSessionQueueWorker", arguments: {domain: site.domain})
    end
  end

  def should_add_job?(site)
    PopulateSessionQueueWorker.should_run?(site) &&
      PopulateSessionQueueWorker.jobs_in_flight_with_domain(site.domain).empty?
  end
end
