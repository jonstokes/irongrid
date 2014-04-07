def service_list
  %w(DeleteEndedAuctionsService ReadSitesService CdnService UpdateListingImagesService)
end

def notify(string)
  puts "[#{Time.now.utc}] #{string}"
end

def start_service(svc)
  service_class = Object.const_get svc
  notify "Starting service #{service_class}..."
  service = service_class.new
  service.start
  notify "#{service_class} started!"
  service
end

def reset_sidekiq_stats
  notify "Resetting Sidekiq stats..."
  Sidekiq::Stats.new.reset
  Sidekiq::RetrySet.new.clear
end

def clear_sidekiq_queues
  notify "Clearing Sidekiq queues..."
  %w(fast_db crawls).each do |q|
    Sidekiq::Queue.new(q).clear
  end
end

def archive_log_Records
  notify "Archiving Log Records..."
  LogRecord.archive_all
end

def boot_services
  services = []
  service_list.each do |svc|
    notify "  booting #{svc}"
    services << start_service(svc)
    sleep 10
  end
  notify "All services booted!"
  services
  dead_service = nil
  sleep 1 while !(dead_service = services.find { |s| s.thread.status.nil? })
  Airbrake.notify(dead_service.thread_error)
  raise dead_service.thread_error
end

namespace :service do
  task :clean_boot_all => :environment do
    notify "Booting services for #{Rails.env.upcase} environment:"
    reset_stats
    clear_sidekiq_queues
    archive_log_Records
    boot_services
  end

  task :reboot_all => :environment do
    notify "Rebooting services for #{Rails.env.upcase} environment:"
    reset_sidekiq_stats
    boot_services
  end

  task :reset_sidekiq_stats => :environment do
    reset_sidekiq_stats
  end
end
