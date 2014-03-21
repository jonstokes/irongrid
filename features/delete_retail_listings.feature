Feature: Delete or Deactivate Listings

  @wip
  Scenario:
    Delete an ended auction listing

    Given the following auction listing exists in the database:
      |url                          | image        |auction_ends
      |"http://www.retailer.com/1" | TEST_IMAGE_1 | 1.day.ago

    Given an auction listing exists in the database with auction_ends 1 day ago
    And an auction listing exists in the database with image TEST_IMAGE_1
    And the CDN has TEST_IMAGE_1 last modified 2 weeks ago

    When I drain DeleteEndedAuctionsWorker
    Then 1 retail listing should be added to the DeleteListingsQueue

    When I drain DeleteListingsWorker
    Then the database should have 0 auction listings

    When I drain DeleteCdnImagesWorker
    Then the CDN should not have TEST_IMAGE_1

  @wip
  Scenario:
    Delete a sold classified listing

    Given a set of pages on the retailer.com
    And the following page exists:
      |url                          | type
      |"http://www.retailer.com/1" | classified_sold
    And the following classified listing exists in the database
      |url                          | image        | updated_at
      |"http://www.retailer.com/1" | TEST_IMAGE_1 | 2.days.ago
    And the CDN has TEST_IMAGE_1 last modified 2 weeks ago

    When I drain RefreshLinksWorker
    Then the LinkSet for retailer.com should have 1 link
    And Sidekiq should have 1 ScrapePagesWorker

    When I drain ScrapePagesWorker
    Then the LinkSet for www.retailer.com should have 0 links
    And the ImageSet for www.retailer.com should have 0 links
    And Sidekiq should have 1 WriteListingWorker with action "delete"

    When I drain WriteListingWorker
    Then the database should have 0 retail listings
    And the search index should have 0 retail listings

    When I drain DeleteCdnImagesWorker
    Then the CDN should not have TEST_IMAGE_1

  @wip
  Scenario:
    Delete a not_found retail listing

    Given a set of pages on the retailer.com
    And the following page exists:
      |url                          | type
      |"http://www.retailer.com/1" | not_found
    And the following retail listing exists in the database
      |url                          | image        |updated_at
      |"http://www.retailer.com/1" | TEST_IMAGE_1 |2.days.ago

    When I drain RefreshLinksWorker
    Then the LinkSet for retailer.com should have 1 link
    And Sidekiq should have 1 ScrapePagesWorker

    When I drain ScrapePagesWorker
    Then the LinkSet for www.retailer.com should have 0 links
    And the ImageSet for www.retailer.com should have 0 links
    And Sidekiq should have 1 WriteListingWorker with action "delete"

    When I drain WriteListingWorker
    Then the database should have 0 retail listings
    And the search index should have 0 retail listings

    When I drain DeleteCdnImagesWorker
    Then the CDN should not have TEST_IMAGE_1

  @wip
  Scenario:
    Delete a 404 retail listing

    Given a set of pages on the retailer.com
    And a page does not exist at http://www.retailer.com/1
    And the following retail listing exists in the database:
      |url                          | image        |updated_at
      |"http://www.retailer.com/1" | TEST_IMAGE_1 |2.days.ago
    And the CDN has TEST_IMAGE_1 last modified 2 weeks ago

    When I drain RefreshLinksWorker
    Then the LinkSet for retailer.com should have 1 link
    And Sidekiq should have 1 ScrapePagesWorker

    When I drain ScrapePagesWorker
    Then the LinkSet for www.retailer.com should have 0 links
    And the ImageSet for www.retailer.com should have 0 links
    And Sidekiq should have 1 WriteListingWorker with action "delete"

    When I drain WriteListingWorker
    Then the database should have 0 retail listings
    And the search index should have 0 retail listings

    When I drain DeleteCdnImagesWorker
    Then the CDN should not have TEST_IMAGE_1

  @wip
  Scenario:
    Deactivate an invalid listing

    Given a set of pages on the retailer.com with type not_found
    And the following page exists:
      |url                          | type
      |"http://www.retailer.com/1" | invalid
    And the following listing exists in the database:
      |url                          | image        |updated_at
      |"http://www.retailer.com/1" | TEST_IMAGE_1 |2.days.ago
    And the CDN has TEST_IMAGE_1 last modified 2 weeks ago

    When I drain RefreshLinksWorker
    Then the LinkSet for retailer.com should have 1 link
    And Sidekiq should have 1 ScrapePagesWorker

    When I drain ScrapePagesWorker
    Then the LinkSet for www.retailer.com should have 0 links
    And the ImageSet for www.retailer.com should have 0 links
    And Sidekiq should have 1 WriteListingWorker with action "deactivate"

    When I drain WriteListingWorker
    Then the database should have 0 retail listings
    And the search index should have 0 retail listings

    When I drain DeleteCdnImagesWorker
    Then the CDN should have 1 images


  @wip
  Scenario:
    Delete a removed affiliate listing, but keep the image because
    it's in use by another listing

    Given an affiliate feed with one "remove" entry
    And the following retail listing exists in the database:
      |url                          | image        |updated_at
      |"http://www.retailer.com/1" | TEST_IMAGE_1 |2.days.ago
      |"http://www.retailer.com/2" | TEST_IMAGE_1 |2.days.ago
    And the CDN has TEST_IMAGE_1 last modified 2 weeks ago

    When I drain AffiliatesWorker
    Then Sidekiq should have 2 WriteListingsWorker

    When I drain WriteListingsWorker
    Then the database should have 1 retail listings

    When I drain DeleteCdnImagesWorker
    Then the CDN should have TEST_IMAGE_1



