Stretched::Settings.configure do |config|
  config.user             = Figaro.env.stretched_user || "#{Rails.env}@ironsights.com"
  config.connection_pools = Bellbro::Settings.connection_pools
  config.logger           = Rails.logger
end
