class SiteStatsService < CoreService
  SLEEP_INTERVAL = Rails.env.test? ? 1 : 86400

  def jobs
    Site.all.map do |site|
      next unless should_add_job?(site)
      { klass: "SiteStatsWorker", arguments: {domain: site.domain} }
    end.compact
  end

  def should_add_job?
    Time.now - site.stats.try(:[],:updated_at) > 86400
  end
end
