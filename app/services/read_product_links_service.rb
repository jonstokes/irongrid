class ReadProductLinksService < Bellbro::Service

  poll_interval 120
  track_with_schema jobs_started: Integer

  def each_job
    IronCore::Site.each do |site|
      next unless should_add_job?(site)
      yield(klass: 'PullProductLinksWorker', arguments: {domain: site.domain})
    end
  end

  def should_add_job?(site)
    PullProductLinksWorker.should_run?(site) &&
      PullProductLinksWorker.jobs_in_flight_with_domain(site.domain).empty?
  end
end
