RSpec.configure do |config|
  config.before(:each) do
    IronCore::Site.clear_all
  end
end

def site_fixtures_dir
  "#{Rails.root}/spec/fixtures/stretched/registrations/sites"
end

def create_site(domain)
  Site::LoadFromLocal.call(
      domain:    domain,
      directory: site_fixtures_dir,
      user:      Stretched::Settings.user
  ).site
end

def create_sites
  Site::CreateAll.call(
      directory: site_fixtures_dir,
      user:      Stretched::Settings.user,
  )
end
