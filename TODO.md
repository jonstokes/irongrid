# Multi-Engine work list

 * Make synonyms work with IronBase::Settings (testing needed)

 * I'll want to rename ironsights-sites to irongrid-sites, because this
will be a consolidated repo for multiple engines.

 * Globals should go index/globals/



# ValidateListingPresence
 if the url is not_found (either page.not_found or json.not_found)
    delete any existing listings at this url
    fail(:not_found)
 end    
 
# FindOrCreateListing

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
 
# TransformJsonToListing
 copy attributes
 derive attributes
  
  if the listing is invalid
    fail(:invalid)
    
 
# FinishListingDetails
 add product details
 add location
 set digest
 if the listing would dupe another digest
    fail(:duplicate)


# WriteListingToIndex
 update image
 save listing

   
