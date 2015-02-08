class SiteStatsService < Bellbro::Service
  track_with_schema jobs_started: Integer
  poll_interval 3600

  def each_job
    IronCore::Site.each do |site|
      next unless should_add_job?(site)
      yield(klass: "SiteStatsWorker", arguments: {domain: site.domain})
    end
  end

  def should_add_job?(site)
    SiteStatsWorker.should_run?(site.domain)
  end
end
