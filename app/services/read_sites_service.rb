class ReadSitesService < Bellbro::Service
  poll_interval Rails.env.test? ? 0.1 : 60
  track_with_schema jobs_started: Integer

  def each_job
    IronCore::Site.each do |site|
      next unless should_add_job?(site)
      yield(klass: "PopulateSessionQueueWorker", arguments: {domain: site.domain})
    end
  end

  def should_add_job?(site)
    PopulateSessionQueueWorker.should_run?(site) &&
      PopulateSessionQueueWorker.jobs_in_flight_with_domain(site.domain).empty?
  end
end
