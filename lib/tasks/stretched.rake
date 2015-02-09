def stretched_user
  ENV['STRETCHED_USER'] || Stretched::Settings.user
end

namespace :stretched do
  namespace :registration do
    task :create_all => :environment do
      StretchedUtils.register_globals(stretched_user)
      StretchedUtils.register_sites(stretched_user)
    end

    task :create_globals => :environment do
      StretchedUtils.register_globals(stretched_user)
    end

    task :create_sites => :environment do
      StretchedUtils.register_sites(stretched_user)
    end
  end

  namespace :user do
    task create_all: :environment do
      %w(
        production@ironsights.com
        development@ironsights.com
        test@ironsights.com
        production-validator@ironsights.com
        development-validator@ironsights.com
        test-validator@ironsights.com
      ).each do |user|
        Stretched::User.create(user)
      end
    end
  end
end
