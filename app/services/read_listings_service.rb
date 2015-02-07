class ReadListingsService < Bellbro::Service

  SLEEP_INTERVAL = Rails.env.test? ? 0.1 : 120
  track_with_schema jobs_started: Integer

  def each_job
    IronCore::Site.each do |site|
      next unless should_add_job?(site)
      yield(klass: "PullListingsWorker", arguments: {domain: site.domain})
    end
  end

  def should_add_job?(site)
    site.listings_queue.any? &&
      PullListingsWorker.jobs_in_flight_with_domain(site.domain).empty?
  end
end
