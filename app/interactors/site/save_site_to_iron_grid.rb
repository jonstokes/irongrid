module Site
  class SaveSiteToIronGrid
    include Interactor

    def call
      context.site = IronCore::Site.new(context.site_data)
      context.site.save
    end
  end
end