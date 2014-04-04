def start_service(svc)
  service_class = Object.const_get svc
  puts "Starting service #{service_class}..."
  service = service_class.new
  service.start
  puts "#{service_class} started!"
  sleep 10
  service
end

def reset_state
  puts "Resetting Sidekiq..."
  Sidekiq::Stats.new.reset
  Sidekiq::RetrySet.new.clear
  %w(fast_db crawls).each do |q|
    Sidekiq::Queue.new(q).clear
  end
  Sidekiq::RetrySet.new.clear
  puts "Archiving existing Log Records..."
  LogRecord.archive_all
end

namespace :service do
  task :boot_all => :environment do
    reset_state
    puts "Booting services for #{Rails.env.upcase} environment:"

    dead_service = nil
    services = []
    %w(DeleteEndedAuctionsService ReadSitesService CdnService).each do |svc|
      puts "  booting #{svc}"
      services << start_service(svc)
    end
    puts "All services booted!"
    sleep 1 while !(dead_service = services.find { |s| s.thread.status.nil? })
    Airbrake.notify(dead_service.thread_error)
    raise dead_service.thread_error
  end

  task :reboot_all => :environment do
    puts "Rebooting services for #{Rails.env.upcase} environment:"

    dead_service = nil
    services = []
    %w(DeleteEndedAuctionsService ReadSitesService CdnService).each do |svc|
      puts "  booting #{svc}"
      services << start_service(svc)
    end
    puts "All services booted!"
    while !(dead_service = services.find { |s| s.thread.status.nil? }) do
      services.each {|s| puts "#{s.class}: #{s.thread.status}"}
      sleep 10
    end
    Airbrake.notify(dead_service.thread_error)
    raise dead_service.thread_error
  end


  task :reset_state => :environment do
    reset_state
  end
end
