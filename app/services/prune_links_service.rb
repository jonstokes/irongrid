class PruneLinksService < CoreService

  def jobs
    Site.all.map do |site|
      next unless should_add_job?(site)
      { klass: "PruneLinksWorker", arguments: {domain: site.domain} }
    end.compact
  end

  def should_add_job?(site)
    PruneLinksWorker.should_run?(site.domain)
  end
end
