class CdnService < CoreService
  def jobs
    Site.active.map do |site|
      next unless should_add_job?(site)
      { klass: "CreateCdnImagesWorker", arguments: {domain: site.domain} }
    end.compact
  end

  def should_add_job?(site)
    ImageQueue.new(domain: site.domain).any? &&
      CreateCdnImagesWorker.jobs_in_flight_with_domain(site.domain).empty?
  end
end
