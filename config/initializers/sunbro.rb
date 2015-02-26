Sunbro::Settings.configure do |config|
  config.proxy_url = Figaro.env.http_proxy
end