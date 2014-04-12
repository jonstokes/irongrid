class ReadSitesService < CoreService

  def jobs
    Site.active.map do |site|
      next unless should_add_job?(site)
      { klass: site.read_with, arguments: {domain: site.domain} }
    end.compact
  end

  def should_add_job?(site)
    site.should_read? && LinkQueue.new(domain: site.domain).empty?
  end
end
