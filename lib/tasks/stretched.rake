namespace :stretched do
  namespace :registration do
    task :create_all => :environment do
      StretchedUtils.register_globals
      StretchedUtils.register_sites
    end

    task :create_globals => :environment do
      StretchedUtils.register_globals
    end

    task :create_sites => :environment do
      StretchedUtils.register_sites
    end
  end

  namespace :user do
    task create_all: :environment do
      %w(
        production@ironsights.com
        staging@ironsights.com
        development@ironsights.com
        test@ironsights.com
        production-validator@ironsights.com
        development-validator@ironsights.com
        staging-validator@ironsights.com
        test-validator@ironsights.com
      ).each do |user|
        Stretched::User.create(user)
      end
    end
  end
end
