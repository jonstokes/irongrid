# Multi-Engine work list

1. Bring back PPR and Shipping specs with new code


2. To generate the correct listing hash in the WriteListing phase,
I'll have to break up the Listing model, with different Listing
constants.

3. IG will need support for more than one ES index mapping, more than
one set of synonyms, etc. I should go ahead and have the synonyms be
generated from ironsights-sites/globals/mappings/*.yml, and I should
save the index JSON in ironsights-sites as well.

4. I'll want to rename ironsights-sites to irongrid-sites, because this
will be a consolidated repo for multiple engines.

5. Globals should go index/globals/

6. Now is the time to use the index mapping for Listing object item_data fields,
   instead of the Listings::LISTING_CONSTANTS file.


