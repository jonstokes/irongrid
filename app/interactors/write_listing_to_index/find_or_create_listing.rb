class WriteListingToIndex
  class FindOrCreateListing
    include Interactor

    def rollback
      if context.listing.persisted?
        if should_destroy?
          context.listing.destroy
        else
          context.listing.deactivate!
        end
      end
    end

    def call
      context.listing = IronBase::Listing.find(listing_id) || IronBase::Listing.new(id: listing_id)
      context.listing.url = {
          purchase: purchase_url,
          page: page_url
      }
    end

    def listing_id
      Digest::MD5.hexdigest(
          "#{base_url}#{context.listing_json.id}"
      )
    end

    def purchase_url
      if affiliate_link_tag
        "#{base_url}#{affiliate_link_tag}"
      elsif share_a_sale?
        share_a_sale_url
      else
        base_url
      end
    end

    def share_a_sale_url
      link = base_url.split(/https?\:\/\//).last
      link = link.to_query('urllink')
      link = link.gsub(".","%2E").gsub("-","%2D")
      "http://www.shareasale.com/r.cfm?u=882338&b=358708&m=37742&afftrack=&#{link}"
    end

    def base_url
      context.listing_json.url || page_url
    end

    def page_url
      if context.page.code == 302    # Temporary redirect, so
        context.page.redirect_from   # preserve original url
      else
        context.page.url
      end
    end

    def affiliate_link_tag
      context.site.affiliate_link_tag
    end

    def share_a_sale?
      context.site.affiliate_program == "ShareASale"
    end

    # Rollback status checkers

    def should_destroy?
      listing_is_duplicate? ||
          auction_ended? ||
          (page_redirected? && listing_is_invalid?)
    end

    def page_redirected?
      [301, 302].include?(context.page.code)
    end

    def listing_is_invalid?
      context.error == 'invalid'
    end

    def auction_ended?
      context.error == 'auction_ended'
    end

    def listing_is_duplicate?
      context.error == 'duplicate'
    end
  end
end