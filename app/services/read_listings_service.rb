class ReadListingsService < CoreService

  SLEEP_INTERVAL = 30

  def jobs
    Site.all.map do |site|
      next unless should_add_job?(site)
      { klass: ConvertJsonToListing, arguments: {domain: site.domain} }
    end.compact
  end

  def should_add_job?(site)
    ObjectQueue.new("#{site.domain}/listings").any?
  end
end
