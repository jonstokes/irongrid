class SiteStatsService < CoreService
  SLEEP_INTERVAL = Rails.env.test? ? 1 : 4.hours.to_i

  def each_job
    Site.each do |site|
      next unless should_add_job?(site)
      yield(klass: "SiteStatsWorker", arguments: {domain: site.domain})
    end
  end

  def should_add_job?(site)
    return true unless time = site.stats.try(:[],:updated_at)
    SiteStatsWorker.should_run?(site.domain) && ((Time.now - time) > SLEEP_INTERVAL)
  end
end
