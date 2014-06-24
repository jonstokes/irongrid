Capybara.register_driver :poltergeist do |app|
  Capybara::Poltergeist::Driver.new(
    app,
    js_errors: false,
    phantomjs_options: ['--load-images=no', '--ignore-ssl-errors=yes']
  )
end
Capybara.default_driver = :poltergeist
Capybara.javascript_driver = :poltergeist
Capybara.run_server = false

pool_size = Figaro.env.session_pool.to_i rescue 10
$session_pool = ConnectionPool.new(timeout: 10, size: pool_size) do
  session = Capybara::Session.new(:poltergeist)
  session.driver.headers = { 'User-Agent' => "Mozilla/5.0 (Macintosh; Intel Mac OS X)" }
  session
end
