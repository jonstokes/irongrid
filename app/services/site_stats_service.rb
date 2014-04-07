class SiteStatsService < CoreService
  SLEEP_INTERVAL = Rails.env.test? ? 1 : 86400

  def jobs
    Site.active.map do |site|
      { klass: "SiteStatsWorker", arguments: {domain: site.domain} }
    end.compact
  end
end
