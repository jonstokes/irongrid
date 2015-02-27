module Site
  class UpdateSiteInIronGrid
    include Interactor
    include Bellbro::Ringable

    before do
      @changed = false
    end

    def call
      ring "Updating site data for #{domain} from #{directory}..."
      site.site_data.members.each do |attr|
        next if [:read_at, :stats].include?(attr)
        @changed = (site.site_data[attr] != local_site.site_data[attr])
        site.site_data[attr] = local_site.site_data[attr]
      end
      site.save
    end

    after do
      if @changed
        ring "  ...#{domain} site data changed."
        site.update(read_at: nil)
      end
    end

    def local_site
      context.local_site ||= IronCore::Site.new(context.site_data)
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
      context.site ||= IronCore::Site.find domain
    end
  end
end