class ReadListingsService < CoreService

  SLEEP_INTERVAL = Rails.env.test? ? 0.1 : 30

  def jobs
    Site.all.map do |site|
      next unless should_add_job?(site)
      { klass: "PullListingsWorker", arguments: {domain: site.domain} }
    end.compact
  end

  def should_add_job?(site)
    Stretched::ObjectQueue.new("#{site.domain}/listings").any?
  end
end
