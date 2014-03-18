Feature: Delete or Deactivate Listings

  @wip
  Scenario:
    Delete an ended auction listing

    Given the following auction listing exists in the database:
      |url                          | image        |auction_ends
      |"http://www.test-site.com/1" | TEST_IMAGE_1 | 1.day.ago

    Given an auction listing exists in the database with auction_ends 1 day ago
    And an auction listing exists in the database with image TEST_IMAGE_1

    When I run DeleteEndedAuctionsWorker
    Then 1 listing should be added to the DeleteDeactivateListingsQueue

    When I run DeleteDeactivateListingsWorker
    Then the database should have 0 auction listings

    When I run UpdateImagesWorker
    Then the CDN should not have TEST_IMAGE_1

  @wip
  Scenario:
    Delete a sold classified listing

    Given a set of pages on the test-site.com
    And the following page exists:
      |url                          | type
      |"http://www.test-site.com/1" | classified_sold
    And the following classified listing exists in the database
      |url                          | image        | updated_at
      |"http://www.test-site.com/1" | TEST_IMAGE_1 | 2.days.ago

    When I run UpdateListingsWorker for test-site.com
    Then the LinkSet for test-site.com should have 1 link

    When I empty the LinkSet for test-site.com with CreatePagesWorker for test-site.com
    Then the PageQueue should have 1 page

    When I empty the PageQueue with ParsePagesWorker
    Then the ParsedPageQueue should have 0 pages
    And the ImageSet for test-site.com should have 0 links
    And the DeleteDeactivateListingsQueue should have 1 listing

    When I run DeleteDeactivateListingsWorker
    Then the database should have 0 classified listings
    And the search index should have 0 classified listings

    When I run UpdateImagesWorker
    Then the CDN should not have TEST_IMAGE_1

  @wip
  Scenario:
    Delete a not_found retail listing

    Given a set of pages on the test-site.com
    And the following page exists:
      |url                          | type
      |"http://www.test-site.com/1" | not_found
    And the following retail listing exists in the database
      |url                          | image        |updated_at
      |"http://www.test-site.com/1" | TEST_IMAGE_1 |2.days.ago

    When I run UpdateListingsWorker for test-site.com
    Then the LinkSet for test-site.com should have 1 link

    When I empty the LinkSet for test-site.com with CreatePagesWorker for test-site.com
    Then the PageQueue should have 1 page

    When I empty the PageQueue with ParsePagesWorker
    Then the ParsedPageQueue should have 0 pages
    And the ImageSet for test-site.com should have 0 links
    And the DeleteDeactivateListingsQueue should have 1 listing

    When I run DeleteDeactivateListingsWorker
    Then the database should have 0 retail listings
    And the search index should have 0 retail listings

    When I run UpdateImagesWorker
    Then the CDN should not have TEST_IMAGE_1

  @wip
  Scenario:
    Delete a 404 retail listing

    Given a set of pages on the test-site.com
    And a page does not exist at http://www.test-site.com/1
    And the following retail listing exists in the database:
      |url                          | image        |updated_at
      |"http://www.test-site.com/1" | TEST_IMAGE_1 |2.days.ago

    When I run UpdateListingsWorker for test-site.com
    Then the LinkSet for test-site.com should have 1 link

    When I empty the LinkSet for test-site.com with CreatePagesWorker for test-site.com
    Then the PageQueue should have 0 pages
    And the DeleteDeactivateListingsQueue should have 1 listing

    When I run DeleteDeactivateListingsWorker
    Then the database should have 0 retail listings
    And the search index should have 0 retail listings

    When I run UpdateImagesWorker
    Then the CDN should have 0 images

  @wip
  Scenario:
    Deactivate an invalid listing

    Given a set of pages on the test-site.com with type not_found
    And the following page exists:
      |url                          | type
      |"http://www.test-site.com/1" | invalid
    And the following listing exists in the database:
      |url                          | image        |updated_at
      |"http://www.test-site.com/1" | TEST_IMAGE_1 |2.days.ago

    When I run UpdateListingsWorker for test-site.com
    Then the LinkSet for test-site.com should have 1 link

    When I empty the LinkSet for test-site.com with CreatePagesWorker for test-site.com
    Then the PageQueue should have 1 page

    When I empty the PageQueue with ParsePagesWorker
    Then the ParsedPageQueue should have 0 pages
    And the ImageSet for test-site.com should have 0 links
    And the DeleteDeactivateListingsQueue should have 1 listing

    When I run DeleteDeactivateListingsWorker
    Then the database should have 1 retail listings with type "inactive"
    And the search index should have 0 retail listings

    When I run UpdateImagesWorker
    Then the CDN should have 1 images


  @wip
  Scenario:
    Delete a removed affiliate listing

    Given an affiliate feed with one "remove" entry
    And the following retail listing exists in the database:
      |url                          | image        |updated_at
      |"http://www.test-site.com/1" | TEST_IMAGE_1 |2.days.ago

    When I run AffiliatesWorker
    Then DeleteDeactivateQueue should have 1 listing

    When I run the DeleteDeactivateListingsWorker
    Then the database should have 0 retail listings

    When I run UpdateImagesWorker
    Then the CDN should not have TEST_IMAGE_1



