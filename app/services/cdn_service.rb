class CdnService < Bellbro::Service
  SLEEP_INTERVAL = Rails.env.test? ? 1 : 60

  track_with_schema jobs_started: Integer

  def each_job
    IronCore::Site.each do |site|
      next unless should_add_job?(site)
      yield(klass: "CreateCdnImagesWorker", arguments: {domain: site.domain})
    end
  end

  def should_add_job?(site)
    IronCore::ImageQueue.new(domain: site.domain).any? &&
      CreateCdnImagesWorker.jobs_in_flight_with_domain(site.domain).empty?
  end
end
