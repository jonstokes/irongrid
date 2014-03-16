class CoreService < CoreModel
  include SidekiqUtils

  SERVICE_VERB   = "process"      #e.g. "crawl", "scrape"
  SERVICE_CLASS  = CrawlerWorker  # Use class for corresponding worker
  SLEEP_INTERVAL = 3600

  attr_reader :thread, :tracker, :batch_status, :thread_error, :tracker_error

  def initialize(record)
    @done = false
    @completed_batches = Set.new
    @record = record
  end

  def start
    start_thread
    start_tracker
  end

  def start_thread
    @thread = Thread.new do
      begin
        run
      rescue Exception => @thread_error
        @done = true
      end
      Airbrake.notify(@thread_error)
      ActiveRecord::Base.connection.close
      raise @thread_error
    end
  end

  def start_tracker
    @tracker = Thread.new do
      begin
        track
      rescue Exception => @tracker_error
        @done = true
      end
      Airbrake.notify(@tracker_error)
      ActiveRecord::Base.connection.close
      raise @tracker_error
    end
  end

  def stop
    @done = true
    notify "Stopping #{self.class} service..."
    @thread.terminate
    @tracker.terminate
    notify "#{self.class.to_s.capitalize} service stopped."
  end

  def run
    notify "Starting #{self.class} service."
    notify "Found #{sites.count} sites to #{self.class::SERVICE_VERB}."
    begin
      sites.each do |site|
        next unless should_add_job?(site.domain)
        jid = self.class::SERVICE_CLASS.perform_async(domain: site.domain)
        notify "Starting job #{jid} for #{site.domain} #{self.class}."
      end
      sleep self.class::SLEEP_INTERVAL
    end until @done
  end

  def running?
    !@done
  end

  def sites
    db { Site.get_all_sites_for_service(self.class) }
  end

  def track
    begin
      @record.batch_status_update(status_string)
      sleep STATUS_UPDATE_INTERVAL
    end until @done
  end

  def status_string
    @status_string = "Workers:  \n"
    if active_workers.empty?
      @status_string << "0  \n"
    else
      active_workers.each do |w|
        @status_string << "  JID: #{w[:jid]} | Domain: #{w[:domain]} | Started: #{Time.at(w[:time])} | Host: #{w[:host]} \n"
      end
    end

    @status_string << "Jobs:  \n"
    if queued_jobs.empty?
      @status_string << "0  \n"
    else
      queued_jobs.each do |j|
        @status_string << "  JID: #{j[:jid]} | Domain: #{j[:domain]} \n"
      end
    end
  end

  def crawls
    (active_workers + queued_jobs).flatten.compact
  end

  def active_workers
    workers_for_class("#{self.class::SERVICE_CLASS}").map do |w| 
      {
        :domain => worker_domain(w), 
        :jid => worker_jid(w), 
        :host => worker_host(w),
        :time => worker_time(w)
      }
    end
  end

  def queued_jobs
    jobs_for_class("#{self.class::SERVICE_CLASS}").map { |j| {:domain => job_domain(j), :jid => job_jid(j)} }
  end

  def should_add_job?(domain)
    !crawls.find { |c| c[:domain] == domain }
  end
end

