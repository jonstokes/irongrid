Sidekiq.configure_server do |config|
  config.error_handlers << Proc.new { |ex,context| Airbrake.notify_or_ignore(ex,parameters: context) }
  config.redis = { :url => Figaro.env.sidekiq_redis_url, :namespace => ENV['RAILS_ENV'] }
  config.client_middleware do |chain|
    chain.add Sidekiq::Middleware::Client::Batch
  end
  config.server_middleware do |chain|
    chain.add Sidekiq::Middleware::Server::Batch
  end
end

# When in Unicorn, this block needs to go in unicorn's `after_fork` callback:
Sidekiq.configure_client do |config|
  config.error_handlers << Proc.new { |ex,context| Airbrake.notify_or_ignore(ex,parameters: context) }
  config.redis = { :url => Figaro.env.sidekiq_redis_url, :namespace => ENV['RAILS_ENV'] }
  config.client_middleware do |chain|
    chain.add Sidekiq::Middleware::Client::Batch
  end
end
