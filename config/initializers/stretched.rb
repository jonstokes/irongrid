Stretched::Settings.configure do |config|
  config.user             = Figaro.env.stretched_user || "#{Rails.env}@ironsights.com"
  config.logger           = Rails.logger
end

RedisObjects.user = Stretched::Settings.user