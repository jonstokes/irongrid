class SiteStatsService < CoreService
  def jobs
    Site.active.map do |site|
      { klass: "SiteStatsWorker", arguments: {domain: site.domain} }
    end.compact
  end
end
