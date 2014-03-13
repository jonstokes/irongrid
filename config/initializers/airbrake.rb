Airbrake.configure do |config|
  config.api_key = Figaro.env.airbrake_api_key
end if Rails.env.production?
