Feature: Update Retail Listings

  @wip
  Scenario:
    Update a retail listing with RefreshLinksWorker so that it has a new price

    Given a set of pages on the www.retailer.com
    And the following page exists:
      |url                             | price
      |"http://www.retailer.com/1" | $2.00
    And the following retail listing exists in the database
      |url                             | image        | updated_at | price
      |"http://www.retailer.com/1" | TEST_IMAGE_1 | 2.days.ago | $1.00

    When I drain RefreshLinksWorker
    Then the LinkSet for www.retailer.com should have 1 link
    And Sidekiq should have 1 CreateLinksWorker

    When I drain CreateLinksWorker
    Then the LinkSet for www.retailer.com should have 1 link
    And Sidekiq should have 1 ScrapePagesWorker

    When I drain ScrapePagesWorker
    Then the LinkSet for www.retailer.com should have 0 links
    And the ImageSet for www.retailer.com should have 0 links
    And Sidekiq should have 1 WriteListingWorker with action "update"

    When I drain WriteListingWorker
    Then the database should have 1 retail listing
    And the search index should have 1 retail listing
    And the database should have 0 retail listings without an image
    And the search index should have 0 retail listings without an image
    And the database should have 1 retail listing with price $2.00
    And the search index should have 1 retail listing with price $2.00

  @wip
  Scenario:
    Update a retail listing so that it has a new image

    Given a set of pages on the www.retailer.com
    And the following page exists:
      |url                             | image
      |"http://www.retailer.com/1" | TEST_IMAGE_2
    And the following retail listing exists in the database
      |url                             | image        | updated_at
      |"http://www.retailer.com/1" | TEST_IMAGE_1 | 2.days.ago

    When I drain RefreshLinksWorker
    Then the LinkSet for www.retailer.com should have 1 link
    And Sidekiq should have 1 CreateLinksWorker

    When I drain CreateLinksWorker
    Then the LinkSet for www.retailer.com should have 1 link
    And Sidekiq should have 1 ScrapePagesWorker

    When I drain ScrapePagesWorker
    Then the LinkSet for www.retailer.com should have 0 links
    And the ImageSet for www.retailer.com should have 1 link
    And Sidekiq should have 1 WriteListingWorker with action "update"

    When I drain WriteListingWorker
    Then the database should have 1 retail listings
    And the search index should have 1 retail listings
    And the database should have 1 retail listings without an image
    And the search index should have 1 retail listings without an image

    When I drain CreateCdnImagesWorker
    Then the ImageSet should have 0 links
    And the CDN should have 1 image
    And Sidekiq should have 1 UpdateListingImageWorker

    When I drain UpdateListingImageWorker
    Then the database should have 1 retail listing with an image
    And the search index should have 1 retail listing with an image


  @wip
  Scenario:
    Update a retail listing with AffiliatesWorker so that it has a new price

    Given an affiliate feed with one "update" entry
    And the following retail listing exists in the database
      |url                          | image        | updated_at | price
      |"http://www.affiliate.com/1" | TEST_IMAGE_1 | 2.days.ago | $1.00

    When I drain AffiliatesWorker for www.affiliate.com
    Then the ImageSet for www.affiliate.com should have 1 link
    And Sidekiq should have 1 WriteListingsWorker

    When I drain WriteListingWorker
    Then the database should have 1 retail listings
    And the search index should have 1 retail listings
    And the database should have 1 retail listing with price $2.00
    And the search index should have 1 retail listing with price $2.00

    When I drain CreateCdnImages for www.affiliate.com from Sidekiq
    Then the ImageSet should have 0 links
    And the CDN should have 1 image
    And Sidekiq should have 1 UpdateListingImageWorker

    When I drain UpdateListingImageWorker
    Then the database should have 1 retail listing with an image
    And the search index should have 1 retail listing with an image
    And the database should have 0 retail listings without an image
    And the search index should have 0 retail listings without an image

