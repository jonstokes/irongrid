module StretchedTools
  module IndexMapping

    def self.schema
      {
        properties: {
          type: {
            validate: {
              presence: true,
              keyword: {
                accept: ["RetailListing", "ClassifiedListing", "AuctionListing"]
              }
            }
          },
          title: {
            validate: { presence: true },
          },
          url: {
            validate: {
              presence: true,
              uri: {
                scheme: :any,
                restrict_domain: true,
              }
            }
          },
          price_in_cents: {
            extract: { source: :price, extractor: :price_extractor }
          },
          sale_price_in_cents: {
            extract: { source: :sale_price, extractor: :price_extractor }
          },
          buy_now_price_in_cents: {
            extract: { source: :buy_now_price, extractor: :price_extractor }
          },
          reserve_in_cents: {
            extract: { source: :reserve, extractor: :price_extractor }
          },
          minimum_bid_in_cents: {
            extract: { source: :minimum_bid, extractor: :price_extractor }
          },
          current_bid_in_cents: {
            extract: { source: :current_bid, extractor: :price_extractor }
          },
          availability: {
            validate: {
              presence: true,
              keyword: {
                accept: ["in_stock", "out_of_stock", "unknown"]
              }
            }
          },
          item_condition: {
            validate: {
              presence: true,
              keyword: {
                accept: ["New", "Used", "Unknown"]
              }
            }
          },
          image_source: {
            page_adapter: {
              filters: [:truncate_query_strings]
            },
            validate: {
              uri: {
                scheme: [:http, :https],
                domain_must_match: true,
                extension: {
                  accept: [".png", ".jpg", ".jpeg", ".gif", ".bmp"]
                }
              }
            }
          },
          category1: {
            validate: {
              presence: true,
              keyword: {
                accept: ["Guns", "Ammunition", "Optics", "Accessories", "None"]
              }
            }
          },
          grains: {
            validate: {
              range: { gte: 1, lte: 500 }
            },
          },
          caliber: {
            extract: { source: :caliber,  extractor: :caliber_extractor },
          },
          manufacturer: {
            extract: { source: :manufacturer, extractor: :manufacturer_extractor },
          },
        }
      }
    end

    def self.settings
      {
        properties: {
          filters: {
            caliber_synonyms: {
              type: :synonym,
              synonyms: ElasticTools::Synonyms.explicit_mappings(:caliber)
            },
            manufacturer_synonyms: {
              type: :synonym,
              synonyms: ElasticTools::Synonyms.explicit_mappings(:manufacturer)
            },
          },
          dictionaries: {
            caliber_terms: {
              type: :dictionary,
              dictionary: ElasticTools::Synonyms.calibers
            },
            manufacturer_terms: {
              type: :dictionary,
              dictionary: ElasticTools::Synonyms.manufacturers
            },
          },
          extractors: {
            extractor: {
              caliber_extractor: {
                type:   :custom,
                filter: [:lowercase, :scrub_whitespace, :scrub_punctuation, :scrub_dots, :scrub_calibers, :restore_dots, :caliber_synonyms],
                extract_terms: {
                  dictionary: :caliber_terms,
                  terms:  :first # other options: :last, :most_popular, :least_popular, :cat_all
                }
              },
              manufacturer_extractor: {
                type:   :custom,
                filter: [:lowercase, :scrub_whitespace, :scrub_punctuation, :manufacturer_synonyms],
                extract_terms: {
                  dictionary: :manufacturer_terms,
                  terms:  :first # other options: :last, :most_popular, :least_popular, :cat_all
                }
              },
              grains_extractor: {
                type:   :custom,
                filter: [:lowercase, :scrub_whitespace, :scrub_punctuation, :scrub_grains],
              },
              number_of_rounds_extractor: {
                type:   :custom,
                filter: [:lowercase, :scrub_whitespace, :scrub_punctuation, :scrub_rounds],
              },
              price_extractor: { type: :price, currency: :usd, output: :cents },
            }
          },
        },
      }
    end
  end
end

