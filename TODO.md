# Multi-Engine work list

1. In addition to a domain/shipping Loadable::Script, I need
a domain/product_details Loadable::Script that runs in the 
SetProductDetails interactor.

2. Move the PPR calcs to this domain/product_details script.

3. To generate the correct listing hash in the WriteListing phase,
I'll have to break up the Listing model, with different Listing
constants.

4. IG will need support for more than one ES index mapping, more than
one set of synonyms, etc.
