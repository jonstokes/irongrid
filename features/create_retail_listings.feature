Feature: Create Retail Listings

  @wip
  Scenario:
    Create retail listings from a site with valid and invalid pages

    Given the LinkSet for test-site.com is populated

    When I empty the LinkSet for test-site.com with CreatePagesWorker for test-site.com
    Then the PageQueue should have 20 pages

    When I empty the PageQueue with ParsePagesWorker
    Then the ParsedPageQueue should have 10 pages
    And the ImageSet for test-site.com should have 10 links

    When I run CreateUpdateListingsWorker
    Then the database should have 10 retail listings
    And the search index should have 10 retail listings
    And the database should have 10 retail listings with a nil image
    And the search index should have 10 retail listings with a nil image

    When I empty the ImageSet for test-site.com with CreateCdnImagesWorker for test-site.com
    Then the CDN should have 10 images

    When I run the UpdateListingImagesWorker
    Then the database should have 0 retail listings with a nil image
    And the search index should have 0 retail listings with a nil image

  @wip
  Scenario:
    Create retail listings from a set of valid and invalid links

    Given the LinkSet for test-site.com is populated
    And the LinkSet for test-site.com is seeded with 5 invalid links

    When I empty the LinkSet for test-site.com with CreatePagesWorker for test-site.com
    Then the PageQueue should have 20 pages

    When I empty the PageQueue with ParsePagesWorker
    Then the ParsedPageQueue should have 10 pages
    And the ImageSet for test-site.com should have 10 links

    When I run CreateUpdateListingsWorker
    Then the database should have 10 retail listings
    And the search index should have 10 retail listings
    And the database should have 10 retail listings with a nil image
    And the search index should have 10 retail listings with a nil image

    When I empty the ImageSet for test-site.com with CreateCdnImagesWorker for test-site.com
    Then the CDN should have 10 images

    When I run the UpdateListingImagesWorker
    Then the database should have 0 retail listings with a nil image
    And the search index should have 0 retail listings with a nil image

  @wip
  Scenario:
    Create ten retail listings from an affiliate feed

    Given an affiliate feed with 10 "create" entries
    When I run AffiliatesWorker
    Then the PageQueue should have 10 pages

    When I empty the PageQueue with ParsePagesWorker
    Then the ParsedPageQueue should have 10 pages

    When I empty the ParsedPageQueue with CreateUpdateListingsWorker
    Then the database should have 10 retail listings
    And the search index should have 10 retail listings
    And the CDN should have 10 images

  @wip
  Scenario:
    Create ten retail listings from an rss feed

    Given an rss feed with 10 entries
    When I run RssWorker
    Then the PageQueue should have 10 pages

    When I empty the PageQueue with ParsePagesWorker
    Then the ParsedPageQueue should have 10 pages

    When I empty the ParsedPageQueue with CreateUpdateListingsWorker
    Then the database should have 10 retail listings
    And the search index should have 10 retail listings
    And the CDN should have 10 images

