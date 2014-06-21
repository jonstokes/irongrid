class SiteStatsService < CoreService
  SLEEP_INTERVAL = Rails.env.test? ? 1 : 86400

  def jobs
    Site.all.map do |site|
      next unless should_add_job?(site)
      { klass: "SiteStatsWorker", arguments: {domain: site.domain} }
    end.compact
  end

  def should_add_job?(site)
    return true unless time = site.stats.try(:[],:updated_at)
    (Time.now - time) > 86400
  end
end
