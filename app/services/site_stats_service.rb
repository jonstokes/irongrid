class SiteStatsService < CoreService

  def each_job
    Site.each do |site|
      next unless should_add_job?(site)
      yield(klass: "SiteStatsWorker", arguments: {domain: site.domain})
    end
  end

  def should_add_job?(site)
    SiteStatsWorker.should_run?(site.domain)
  end
end
