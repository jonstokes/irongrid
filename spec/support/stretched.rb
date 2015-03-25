def initialize_stretched
  # Clear stretched redis db
  Stretched::Registration.with_connection { |c| c.flushdb }

  # Create global and engine-specific registrations
  SiteLibrary::CreateGlobalRegistrations.call
  SiteLibrary::CreateEngineRegistrations.call

  # Ensure that extensions stored in redis are registered locally
  Stretched::Extension.register_all if Stretched::Extension.registry.empty?
end

initialize_stretched

RSpec.configure do |config|
  config.before(:each) do
    initialize_stretched
  end
end

