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
      context.listing = find_or_create_listing
      context.listing.url = {
          purchase: purchase_url,
          page: current_url
      }
    end

    def find_or_create_listing
      results = IronBase::Listing.find(original_listing_id)
      return results.hits.first if results

      if current_listing_id != original_listing_id
        results = IronBase::Listing.find(current_listing_id)
        return results.hits.first if results
      end

      IronBase::Listing.new(id: current_listing_id)
    end

    def current_listing_id
      Digest::MD5.hexdigest(
          "#{base_url}#{context.listing_json.id}"
      )
    end

    def original_listing_id
      Digest::MD5.hexdigest(
          "#{original_url}#{context.listing_json.id}"
      )
    end

    def purchase_url
      if affiliate_link_tag
        "#{base_url}#{affiliate_link_tag}"
      elsif share_a_sale?
        share_a_sale_url
      elsif avantlink?
        avantlink_url
      else
        base_url
      end
    end

    def avantlink_url
      link = base_url.to_query('url')
      "#{context.site.affiliate_link_prefix}#{link}"
    end

    def share_a_sale_url
      link = base_url.split(/https?\:\/\//).last
      link = link.to_query('urllink')
      link = link.gsub(".","%2E").gsub("-","%2D")
      "#{context.site.affiliate_link_prefix}#{link}"
    end

    def base_url
      context.listing_json.url || current_url
    end

    def current_url
      if context.page.code == 302    # Temporary redirect, so
        context.page.redirect_from   # preserve original url
      else
        context.page.url
      end
    end

    def original_url
      context.listing_json.url || context.page.redirect_from || context.page.url
    end

    def affiliate_link_tag
      context.site.affiliate_link_tag
    end

    def share_a_sale?
      context.site.affiliate_program.try(:downcase) == 'shareasale'
    end

    def avantlink?
      context.site.affiliate_program.try(:downcase) == 'avantlink'
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