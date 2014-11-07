class SetUrl
  include Interactor

  def call
    context.url = Hashie::Mash.new(
        page: page_url,
        purchase: purchase_url
    )
  end

  rollback do
    next unless context.status == :not_found
    [context.page.redirect_from, context.page.url].each do |url|
      Listing.find_by_url(url).each do |listing|
        listing.destroy
      end
    end
  end

  def page_url
    if context.page.code == 302    # Temporary redirect, so
      context.page.redirect_from   # preserve original url
    else
      context.page.url
    end
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

  def base_url
    listing_json.url || page_url
  end

  def share_a_sale_url
    link = base_url.split(/https?\:\/\//).last
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

  def listing_json
    context.listing_json
  end
end