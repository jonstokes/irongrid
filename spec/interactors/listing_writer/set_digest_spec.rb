require 'spec_helper'

describe ListingWriter::SetDigest do
  it 'should correctly digest a listing' do
    site = create_site 'www.hyattgunstore.com'
    opts = {
      site: site,
      listing: Hashie::Mash.new(
        url: {
            page: "http://www.hyattgunstore.com/federal-xm855-5.56-ammo-62-grain-fmj-420-rounds-on-30-round-stripper-clips.html",
            purchase: "http://www.hyattgunstore.com/federal-xm855-5.56-ammo-62-grain-fmj-420-rounds-on-30-round-stripper-clips.html"
        },
        type: "RetailListing",
        title: "Federal XM855 5.56 Ammo 62 Grain FMJ, 420 Rounds, Stripper Clips in Ammo Can",
        product: {
            category1: "Ammunition",
            caliber_category: "rifle",
            manufacturer: "Federal",
            caliber: "5.56 NATO",
            number_of_rounds: 420,
            grains: 62
        },
        seller: {
            site_name: "Hyatt Gun Store",
            domain: "www.hyattgunstore.com",
        },
        description: "Federal 5.56 Ammo in a can is available in 420 round or 840 round ammo cans. The cans are packed with 30 round boxes of (3) 10 shot strip clips. This ammo is 62 grain full metal jacket. Shipped in a 30 caliber military ammo can.",
        keywords: "Federal XM855 5.56mm 62 Grain FMJ, 420 Rounds on 30-Round Stripper Clips,",
        image: {
          source: "http://www.hyattgunstore.com/images/P/76472-P.jpg",
          download_attempted: false
        },
        condition: "New",
        availability: "In Stock",
        price: {
          current: 34999,
          per_round: 83,
          price_on_request: nil,
          list: nil,
          sale: 34999,
          buy_now: nil,
          current_bid: nil,
          minimum_bid: nil,
          reserve: nil,
        },
        auction_ends: nil,
        location: {
            source: '3332 Wilkinson Blvd Charlotte, NC 28208',
            city: nil,
            state: nil,
            country: nil,
            latitude: nil,
            longitude: nil,
            state_code: nil,
            postal_code: nil,
            country_code: nil,
            coordinates: nil
        }
      )
    }

    result = ListingWriter::SetDigest.call(opts)
    expect(result.listing.digest).to eq("88652bbf0db73e01bfbb2cb440eb8a60")
  end
end
