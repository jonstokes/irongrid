# Multi-Engine work list

 * Make synonyms work with IronBase::Settings (testing needed)

 * I'll want to rename ironsights-sites to irongrid-sites, because this
will be a consolidated repo for multiple engines.

 * Globals should go index/globals/


# SetUrl
 Set context.url = { page and purchase }
   
# FindOrCreateListing
  rollback do
    if not_found
        delete any existing listings at this url
    elsif the listing is persisted?
        if from a redirect || status(:duplicate)
            destroy
        else
            deactivate
        end
    end
 end
 
 set listing.id
 find or create listing object
 
# MergeJsonIntoListing
 set listing.url
 copy listing attributes 
 
# ValidateListing
 if the url is not_found (either page.not_found or json.not_found or auction ended)
    fail(:not_found)
 end 
 if the listing is invalid?
    fail(:invalid)

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

   
