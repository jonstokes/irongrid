IronCore::Settings.configure do |config|
  config.connection_pools = Bellbro::Settings.connection_pools
  config.logger = Rails.logger
end
