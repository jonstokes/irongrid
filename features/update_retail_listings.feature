Feature: Update Retail Listings

  @wip
  Scenario:
    Update a retail listing with UpdateListingsWorker so that it has a new price

    Given a set of pages on the test-site.com
    And the following page exists:
      |url                          | price
      |"http://www.test-site.com/1" | $2.00
    And the following retail listing exists in the database
      |url                          | image        | updated_at | price
      |"http://www.test-site.com/1" | TEST_IMAGE_1 | 2.days.ago | $1.00

    When I run UpdateListingsWorker for test-site.com
    Then 1 link should be added to the LinkSet for test-site.com

    When I empty the LinkSet for test-site.com with CreatePagesWorker for test-site.com
    Then 1 page should be added to the PageQueue

    And I empty the PageQueue with ParsePagesWorker
    Then 1 page should be added to the ParsedPageQueue
    And 1 link should be added to the ImageSet for test-site.com

    When I run CreateUpdateListingsWorker
    Then the database should have 1 retail listings
    And the search index should have 1 retail listings
    And the database should have 0 retail listings with a nil image
    And the search index should have 0 retail listings with a nil image
    And the database should have 1 retail listing with price $2.00
    And the search index should have 1 retail listing with price $2.00

    When I empty the ImageSet for test-site.com with CopyImagesToCdnWorker for test-site.com
    Then the CDN should have 1 images

    When I run the UpdateImagesWorker
    Then the database should have 0 retail listings with a nil image
    And the search index should have 0 retail listings with a nil image

  @wip
  Scenario:
    Update a retail listing with CreateListingsWorker so that it has a new price

    Given a set of pages on the test-site.com
    And the following page exists:
      |url                          | price
      |"http://www.test-site.com/1" | $2.00
    And the following retail listing exists in the database
      |url                          | image        | updated_at | price
      |"http://www.test-site.com/1" | TEST_IMAGE_1 | 2.days.ago | $1.00

    When I run CreateListingsWorker for test-site.com
    Then the LinkSet for test-site.com should have 20 links

    When I empty the LinkSet for test-site.com with CreatePagesWorker for test-site.com
    Then the PageQueue should have 20 pages

    And I empty the PageQueue with ParsePagesWorker
    Then the ParsedPageQueue should have 10 pages
    And the ImageSet for test-site.com should have 10 links

    When I run CreateUpdateListingsWorker
    Then the database should have 10 retail listings
    And the search index should have 10 retail listings
    And the database should have 9 retail listings with a nil image
    And the search index should have 9 retail listings with a nil image
    And the database should have 1 retail listing with price $2.00
    And the search index should have 1 retail listing with price $2.00

    When I empty the ImageSet for test-site.com with CopyImagesToCdnWorker for test-site.com
    Then the CDN should have 10 images

    When I run the UpdateImagesWorker
    Then the database should have 0 retail listings with a nil image
    And the search index should have 0 retail listings with a nil image

  @wip
  Scenario:
    Update a retail listing so that it has a new image

    Given a set of pages on the test-site.com
    And the following page exists:
      |url                          | image
      |"http://www.test-site.com/1" | TEST_IMAGE_2
    And the following retail listing exists in the database
      |url                          | image        | updated_at
      |"http://www.test-site.com/1" | TEST_IMAGE_1 | 2.days.ago

    When I run UpdateListingsWorker for test-site.com
    Then the LinkSet for test-site.com should have 1 link

    When I empty the LinkSet for test-site.com with CreatePagesWorker for test-site.com
    Then the PageQueue should have 1 page

    And I empty the PageQueue with ParsePagesWorker
    Then the ParsedPageQueue should have 1 page
    And the ImageSet for test-site.com should have 1 link

    When I run CreateUpdateListingsWorker
    Then the database should have 1 retail listings
    And the search index should have 1 retail listings
    And the database should have 1 retail listings with a nil image
    And the search index should have 1 retail listings with a nil image

    When I empty the ImageSet for test-site.com with CopyImagesToCdnWorker for test-site.com
    Then the CDN should have 1 image

    When I run the UpdateImagesWorker
    Then the database should have 0 retail listings with a nil image
    And the search index should have 0 retail listings with a nil image

  @wip
  Scenario:
    Update a retail listing with AffiliatesWorker so that it has a new price

    Given an affiliate feed with one "update" entry
    And the following retail listing exists in the database
      |url                          | image        | updated_at | price
      |"http://www.test-site.com/1" | TEST_IMAGE_1 | 2.days.ago | $1.00

    When I run AffiliatesWorker for test-site.com
    Then the LinkSet for test-site.com should have 1 link

    When I empty the LinkSet for test-site.com with CreatePagesWorker for test-site.com
    Then the PageQueue should have 1 page

    And I empty the PageQueue with ParsePagesWorker
    Then the ParsedPageQueue should have 1 page
    And the ImageSet for test-site.com should have 0 links

    When I run CreateUpdateListingsWorker
    Then the database should have 1 retail listings
    And the search index should have 1 retail listings
    And the database should have 0 retail listings with a nil image
    And the search index should have 0 retail listings with a nil image
    And the database should have 1 retail listing with price $2.00
    And the search index should have 1 retail listing with price $2.00


