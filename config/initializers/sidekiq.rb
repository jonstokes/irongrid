def sidekiq_redis_url
  PoolBoy::Settings.redis_config[:sidekiq][:url]
end

Sidekiq.configure_server do |config|
  config.error_handlers << Proc.new { |ex,context| Airbrake.notify_or_ignore(ex,parameters: context) }
  config.redis = { :url => sidekiq_redis_url }
end

# When in Unicorn, this block needs to go in unicorn's `after_fork` callback:
Sidekiq.configure_client do |config|
  config.error_handlers << Proc.new { |ex,context| Airbrake.notify_or_ignore(ex,parameters: context) }
  config.redis = { :url => sidekiq_redis_url }
end

