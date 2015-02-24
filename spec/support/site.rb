RSpec.configure do |config|
  config.before(:each) do
    IronCore::Site.clear_all
  end
end

def create_site(domain)
  Site::LoadFromLocal.call(
      domain:    domain,
      directory: IronCore::Site.fixtures_dir,
      user:      Stretched::Settings.user
  ).site
end

def create_sites
  Site::CreateAll.call(
      directory: IronCore::Site.fixtures_dir,
      user:      Stretched::Settings.user,
  )
end
