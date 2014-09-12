class PruneLinksService < CoreService

  def each_job
    Site.each do |site|
      next unless should_add_job?(site)
      yield(klass: "PruneLinksWorker", arguments: {domain: site.domain})
    end
  end

  def should_add_job?(site)
    PruneLinksWorker.should_run?(site.domain)
  end
end
