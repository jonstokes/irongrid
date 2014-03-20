Feature: Create Retail Listings

  @wip
  Scenario:
    Create a retail listing from a site with valid and invalid pages

    Given www.retailer.com has 1 valid page and 1 invalid page

    When I drain RefreshLinksWorker
    Then the LinkSet for www.retailer.com should have 0 links
    And Sidekiq should have 1 CreateLinksWorker

    When I drain CreateLinksWorker
    Then the LinkSet for www.retailer.com should have 2 links
    And Sidekiq should have 1 ParsePagesWorker

    When I drain ParsePagesWorker
    Then the LinkSet for www.retailer.com should have 0 links
    And the ImageSet for www.retailer.com should have 1 link
    And Sidekiq should have 1 WriteListingWorker with action "create"

    When I drain WriteListingWorker
    Then the database should have one retail listing
    And the search index should have one retail listing without an image

    When I drain CreateCdnImages for www.retailer.com from Sidekiq
    Then the ImageSet should have 0 links
    And the CDN should have 1 image
    And Sidekiq should have 1 UpdateListingImageWorker

    When I drain UpdateListingImageWorker
    Then the database should have 1 retail listing with an image
    And the search index should have 1 retail listing with an image

  @wip
  Scenario:
    Create retail listings from a set of valid and 404 links

    Given the LinkSet for test-site.com is seeded with 1 valid link
    And the LinkSet for test-site.com is seeded with 1 404 link

    When I drain ParsePagesWorker
    Then the LinkSet for www.retailer.com should have 0 links
    And the ImageSet for www.retailer.com should have 1 link
    And Sidekiq should have 1 WriteListingWorker with action "create"

    When I drain WriteListingWorker
    Then the database should have one retail listing
    And the search index should have one retail listing without an image

    When I drain CreateCdnImagesWorker
    Then the ImageSet should have 0 links
    And the CDN should have 1 image
    And Sidekiq should have 1 UpdateListingImageWorker

    When I drain UpdateListingImageWorker
    Then the database should have 1 retail listing with an image
    And the search index should have 1 retail listing with an image

  @wip
  Scenario:
    Create ten retail listings from an affiliate feed

    Given an affiliate feed with 10 "create" entries

    When I drain AffiliatesWorker
    Then the ImageSet for www.affiliate.com should have 10 links
    And Sidekiq should have 10 WriteListingsWorker

    When I drain WriteListingsWorker
    Then the ImageSet for www.affiliate.com should have 0 links
    And the database should have 10 retail listings without an image
    And the search index should have 10 retail listings

    When I drain CreateCdnImagesWorker
    Then the ImageSet should have 0 links
    And the CDN should have 10 images
    And Sidekiq should have 10 UpdateListingImageWorker

    When I drain UpdateListingImageWorker
    Then the database should have 10 retail listing with an image
    And the search index should have 10 retail listing with an image

  @wip
  Scenario:
    Create ten retail listings from an rss feed

    Given an rss feed with 10 entries

    Then the ImageSet for www.rss.com should have 10 links
    And Sidekiq should have 10 WriteListingsWorker

    When I drain WriteListingsWorker
    Then the ImageSet for www.rss.com should have 0 links
    And the database should have 10 retail listings without an image
    And the search index should have 10 retail listings

    When I drain CreateCdnImagesWorker
    Then the ImageSet should have 0 links
    And the CDN should have 10 images
    And Sidekiq should have 10 UpdateListingImageWorker

    When I drain UpdateListingImageWorker
    Then the database should have 10 retail listing with an image
    And the search index should have 10 retail listing with an image

