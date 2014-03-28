RSpec.configure do |config|
  config.before(:each) do
    Sidekiq.redis { |conn| conn.flushall }
  end
end
