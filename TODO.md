# Migration

 - Run this in dev in an AWS box
 - Edit application.yml accordingly, so that redis is local, etc.
 - Create all sites and stretched registrations in dev
 - load all site scripts in dev
 - Create index
 - Migrate GeoData to Location
 - Migrate listings

# Punch List
 * Enable in-memory caching for loadables
 * Item condition needs to be expanded to included Reman and Reload
 * Adapters need new product aspects in them
 * Set up production IAM key, bucket, policy, etc. for S3 snapshot backups and test it out.

# Bring up test migration for front end
Delete Test Found cluster
Bring up new Found cluster and set ELASTICSEARCH_URL_REMOTE to it in application.yml

RAILS_ENV=production bundle exec rake index:create_with_alias

Set INDEX_NAME in application.yml to actual index name (not alias) from previous command output

RAILS_ENV=production bundle exec migrate:geo_data
RAILS_ENV=production bundle exec migrate:listings

# For front end
 * Once the migration is done, start work on front end

# #############################
# Product Id

## UpdateProductImagesWorker
Need to set this up, along with a service for it

## PullProductsWorker

Pop product json from queue

Find or create new product:
If UPC
    product = IronBase::Product.find(upc)
elsif MPN
    product = IronBase::Product.find_by_mpn
elsif SKU
    product = IronBase::Product.find_by_sku
else
    product = IronBase::Product.new

Merge json into product:
return if product.complete?
product.upc ||= json.upc
product.mpn.normalized << json.mpn unless product.mpn.normalized.include?(json.mpn)
product.sku.normalized << json.sku unless product.sku.normalized.include?(json.sku)
product.category1 ||= product.category1
etc.

product.save


## ProductDetails::IdentifyProduct

IdentifyByUpc
If product = find_by_upc
    context.product = product
else
    products = find_by_mpn || find_by_sku
    context.product = products.select { prod w/ most info and votes }

SetProductDetails
return unless context.product
if context.upc_match
    listing.product = context.product
else
    listing.product.category1 ||= most popular product.category
    listing.product.caliber_category ||= most popular product.caliber_category
    etc.


## FindProduct

If UPC
    product = IronBase::Product.find(upc)
elsif MPN
    product = IronBase::Product.find_by_mpn
elsif SKU
    product = IronBase::Product.find_by_sku


## UpdateProduct
product.mpn << listing.mpn
product.sku << listing.sku
product.caliber ||= listing.caliber
product.number_of_rounds ||= listing.number_of_rounds
product.manufacturer ||= listing.manufacturer


## UpdateListing
listing.product = product

