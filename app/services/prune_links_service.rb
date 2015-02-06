class PruneLinksService < Bellbro::Service
  SLEEP_INTERVAL = Rails.env.test? ? 1 : 120

  def each_job
    IronCore::Site.each do |site|
      next unless should_add_job?(site)
      yield(klass: "PruneLinksWorker", arguments: {domain: site.domain})
    end
  end

  def should_add_job?(site)
    PruneLinksWorker.should_run?(site) &&
      PruneLinksWorker.jobs_in_flight_with_domain(site.domain).empty?
  end
end
