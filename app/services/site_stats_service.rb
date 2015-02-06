class SiteStatsService < Bellbro::Service

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
