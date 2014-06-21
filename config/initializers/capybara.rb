pool_size = Figaro.env.browser_pool.to_i rescue 10

BROWSER_POOL = ConnectionPool.new(timeout: 5, size: pool_size) do
  Capybara.register_driver :poltergeist do |app|
    Capybara::Poltergeist::Driver.new(app, js_errors: false)
  end
  Capybara.default_driver = :poltergeist
  Capybara.javascript_driver = :poltergeist
  session = Capybara::Session.new(:poltergeist)
  session.driver.headers = { 'User-Agent' => "Mozilla/5.0 (Macintosh; Intel Mac OS X)" }
  session
end

