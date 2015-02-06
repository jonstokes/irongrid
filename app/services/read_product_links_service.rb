class ReadProductLinksService < Bellbro::Service

  SLEEP_INTERVAL = Rails.env.test? ? 0.1 : 120

  def each_job
    Site.each do |site|
      next unless should_add_job?(site)
      yield(klass: 'PullProductLinksWorker', arguments: {domain: site.domain})
    end
  end

  def should_add_job?(site)
    site.product_links_queue.any? &&
      PullProductLinksWorker.jobs_in_flight_with_domain(site.domain).empty?
  end
end
