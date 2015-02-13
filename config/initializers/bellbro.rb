Bellbro::Settings.configure do |config|
  config.logger = Rails.logger
end

Bellbro.initialize_redis!