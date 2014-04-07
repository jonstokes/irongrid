class SiteStatsService < CoreService
  SLEEP_INTERVAL = Rails.env.test? ? 1 : 86400

  def jobs
    return [] unless should_add_jobs?
    Site.active.map do |site|
      { klass: "SiteStatsWorker", arguments: {domain: site.domain} }
    end.compact
  end

  def should_add_jobs?
    SiteStatsWorker.workers.empty?
  end
end
