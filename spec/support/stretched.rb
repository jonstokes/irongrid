def initialize_stretched
  Stretched::Registration.with_connection { |c| c.flushdb }
  SiteLibrary::CreateGlobalRegistrations.call
  SiteLibrary::CreateEngineRegistrations.call
end

RSpec.configure do |config|
  config.before(:each) do
    initialize_stretched
  end
end

