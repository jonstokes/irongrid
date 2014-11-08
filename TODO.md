# Multi-Engine work list

 * Make synonyms work with IronBase::Settings (testing needed)

 * I'll want to rename ironsights-sites to irongrid-sites, because this
will be a consolidated repo for multiple engines.

 * Globals should go index/globals/


# SetUrl
 Set context.url = { page and purchase }
 rollback { delete any existing listings at this url }
   
# FindOrCreateListing
 if the url is not_found (either page.not_found or json.not_found)
    fail(:not_found)
 end  
 
 rollback do
    if the listing is persisted?
        if from a redirect || status(:duplicate)
            destroy
        else
            deactivate
        end
    end
 end
 
 find or create listing object

# MergeJsonIntoListing
 if the listing is invalid
    fail(:invalid)  
 set listing.url
 set listing.id
 copy listing attributes 
 if auction is ended?
    fail(:not_found)  
 
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

   
