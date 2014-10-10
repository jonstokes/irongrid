# Multi-Engine work list

1. In addition to a domain/shipping Loadable::Script, I need
a domain/product_details Loadable::Script that runs in the 
SetProductDetails interactor.

- Validate presence
- Set common attributes
- Validate listing
- Set product details
  - identify product (via db)
  - soft categorize
- Run scripts
  - globals/product_details (for PPR, etc.)
  - site/shipping_cost (calculates shipping cost)
  - globals/shipping_details
    - calculates ppr with shipping
    - set discounts with shipping
- Write listing

2. Move the PPR calcs to this domain/product_details script.

Bring back PPR and Shipping specs with new code


3. To generate the correct listing hash in the WriteListing phase,
I'll have to break up the Listing model, with different Listing
constants.

4. IG will need support for more than one ES index mapping, more than
one set of synonyms, etc. I should go ahead and have the synonyms be
generated from ironsights-sites/globals/mappings/*.yml, and I should
save the index JSON in ironsights-sites as well.

5. I'll want to rename ironsights-sites to irongrid-sites, because this
will be a consolidated repo for multiple engines.

6. Globals should go index/globals/

7. Now is the time to use the index mapping for Listing object item_data fields,
   instead of the Listings::LISTING_CONSTANTS file.


