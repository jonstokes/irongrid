module Site
  class SaveSiteToIronGrid
    include Interactor
    include Bellbro::Ringable

    def call
      context.site = IronCore::Site.new(context.site_data)
      ring "Loading site data for #{context.site.domain} to IronGrid from #{context.filename}..."
      context.site.save
    end
  end
end