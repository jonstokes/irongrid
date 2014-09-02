user = Figaro.env.stretched_user rescue "#{Rails.env}@ironsights.com"

Stretched::Settings.configure do |config|
  config.user = user
end
