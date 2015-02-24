module Site
  class UpdateSiteInIronGrid
    include Interactor
    include Bellbro::Ringable

    def call
      local_site = IronCore::Site.new(context.site_data)
      context.changed = false
      ring "Updating #{domain} from #{directory}..."
      site_data.members.each do |attr|
        next if [:read_at, :stats].include?(attr)
        context.changed = (site_data[attr] != local_site.site_data[attr])
        site_data[attr] = local_site.site_data[attr]
      end
      site.save
    end

    def domain
      context.domain
    end

    def directory
      context.directory
    end

    def user
      context.user
    end

    def site
      context.site
    end

    def site_data
      site.site_data
    end
  end
end