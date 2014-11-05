class DeriveAttributes < CoreModel
  include Interactor

  def call
    context.listing.auction_ends = auction_ends
    context.listing.url.purchase = purchase_url
    context.listing.seller = {
        site_name: context.site.name,
        domain: context.site.domain
    }
  end

  def auction_ends
    return unless context.listing[:type] == 'AuctionListing'
    ListingFormat.time(site: context.site, time: context.listing.auction_ends)
  end

  def purchase_url
    if affiliate_link_tag
      tagged_url
    elsif share_a_sale?
      share_a_sale_url
    else
      url
    end
  end

  def url
    context.listing.url.page
  end

  def tagged_url
    "#{url}#{affiliate_link_tag}"
  end

  def share_a_sale_url
    link = url.split(/https?\:\/\//).last
    link = link.to_query('urllink')
    link = link.gsub(".","%2E").gsub("-","%2D")
    "http://www.shareasale.com/r.cfm?u=882338&b=358708&m=37742&afftrack=&#{link}"
  end

  def share_a_sale?
    context.site.affiliate_program == "ShareASale"
  end

  def affiliate_link_tag
    context.site.affiliate_link_tag
  end
end
