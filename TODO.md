# Multi-Engine work list

 * Make synonyms work with IronBase::Settings (testing needed)

 * I'll want to rename ironsights-sites to irongrid-sites, because this
will be a consolidated repo for multiple engines.

 * Globals should go index/globals/


# SetUrl
 Set context.url = { page and purchase }
   
# FindOrCreateListing
 set listing.id
 find or create listing object
 
  rollback do
    if the listing is persisted?
        if from a redirect || status(:duplicate)
            destroy
        else
            deactivate
        end
    end
 end
 
# MergeJsonIntoListing
 fail :invalid if listing is invalid
 set listing.url
 copy listing attributes
 fail :auction_ended if auction ended?
 
# SetProductDetails
 add product details

# RunLoadables
 run loadables for shipping, etc.

# SetLocation
 add location

# SetDigest
 set digest
 if the listing would dupe another digest
    fail(:duplicate)

# SaveListingToIndex
 update image
 save listing

   
