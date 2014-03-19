Feature: Create Retail Listings

  @wip
  Scenario:
    Create a retail listing from a site with valid and invalid pages

    Given www.retailer.com has 1 valid page and 1 invalid page

    When I run RefreshLinksWorker for www.retailer.com
    Then the LinkSet for www.retailer.com should have 0 links
    And Sidekiq should have 1 CreateLinksWorker for www.retailer.com

    When I run CreateLinksWorker for www.retailer.com from Sidekiq
    Then the LinkSet for www.retailer.com should have 2 links
    And Sidekiq should have 1 ParsePagesWorker for www.retailer.com

    When I run ParsePagesWorker for www.retailer.com from Sidekiq
    Then the LinkSet for www.retailer.com should have 0 links
    And the ImageSet for www.retailer.com should have 1 link
    And Sidekiq should have 1 WriteListingWorker with action "create"

    When I run WriteListingWorker from Sidekiq
    Then the database should have one retail listing
    And the search index should have one retail listing without an image

    When I run CreateCdnImages for www.retailer.com from Sidekiq
    Then the ImageSet should have 0 links
    And the CDN should have 1 image
    And Sidekiq should have 1 UpdateListingImageWorker

    When I run UpdateListingImageWorker from Sidekiq
    Then the database should have 1 retail listing with an image
    And the search index should have 1 retail listing with an image

  @wip
  Scenario:
    Create retail listings from a set of valid and 404 links

    Given the LinkSet for test-site.com is seeded with 1 valid link
    And the LinkSet for test-site.com is seeded with 1 404 link

    When I run ParsePagesWorker for www.retailer.com
    Then the LinkSet for www.retailer.com should have 0 links
    And the ImageSet for www.retailer.com should have 1 link
    And Sidekiq should have 1 WriteListingWorker with action "create"

    When I run WriteListingWorker from Sidekiq
    Then the database should have one retail listing
    And the search index should have one retail listing without an image

    When I run CreateCdnImages for www.retailer.com from Sidekiq
    Then the ImageSet should have 0 links
    And the CDN should have 1 image
    And Sidekiq should have 1 UpdateListingImageWorker

    When I run UpdateListingImageWorker from Sidekiq
    Then the database should have 1 retail listing with an image
    And the search index should have 1 retail listing with an image

  @wip
  Scenario:
    Create ten retail listings from an affiliate feed

    Given an affiliate feed with 10 "create" entries

    When I run AffiliatesWorker for www.affiliate.com
    Then the ImageSet for www.affiliate.com should have 10 links
    And Sidekiq should have 10 WriteListingsWorkers

    When I run the WriteListingsWorkers in Sidekiq
    Then the ImageSet for www.affiliate.com should have 0 links
    And the database should have 10 retail listings without an image
    And the search index should have 10 retail listings

    When I run CreateCdnImages for www.retailer.com from Sidekiq
    Then the ImageSet should have 0 links
    And the CDN should have 10 images
    And Sidekiq should have 10 UpdateListingImageWorkers

    When I run UpdateListingImageWorkers from Sidekiq
    Then the database should have 10 retail listing with an image
    And the search index should have 10 retail listing with an image

  @wip
  Scenario:
    Create ten retail listings from an rss feed

    Given an rss feed with 10 entries

    Then the ImageSet for www.rss.com should have 10 links
    And Sidekiq should have 10 WriteListingsWorkers

    When I run the WriteListingsWorkers in Sidekiq
    Then the ImageSet for www.rss.com should have 0 links
    And the database should have 10 retail listings without an image
    And the search index should have 10 retail listings

    When I run CreateCdnImages for www.rss.com from Sidekiq
    Then the ImageSet should have 0 links
    And the CDN should have 10 images
    And Sidekiq should have 10 UpdateListingImageWorkers

    When I run UpdateListingImageWorkers from Sidekiq
    Then the database should have 10 retail listing with an image
    And the search index should have 10 retail listing with an image

