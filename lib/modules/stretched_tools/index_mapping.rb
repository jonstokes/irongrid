module StretchedTools
  module IndexMapping

    def self.index_properties
      {
        properties: {
          type: {
            priority: 5,
            validate: {
              presence: true,
              keyword: {
                accept: ["RetailListing", "ClassifiedListing", "AuctionListing"]
              }
            }
          },
          title: {
            validate: { presence: true }
          },
          url: {
            priority: 5,
            validate: {
              presence: true,
              uri: {
                scheme: :any,
                restrict_domain: true,
              }
            }
          },
          price_in_cents: {
            priority: 4,
            extract: {
              { source: :price, extractor: :price_extractor }
            }
          },
          sale_price_in_cents: {
            priority: 4,
            extract: {
              { source: :sale_price, extractor: :price_extractor }
            }
          },
          buy_now_price_in_cents: {
            priority: 4,
            extract: {
              { source: :buy_now_price, extractor: :price_extractor }
            }
          },
          reserve_in_cents: {
            priority: 4,
            extract: {
              { source: :reserve, extractor: :price_extractor }
            }
          },
          minimum_bid_in_cents: {
            priority: 4,
            extract: {
              { source: :minimum_bid, extractor: :price_extractor }
            }
          },
          current_bid_in_cents: {
            priority: 4,
            extract: {
              { source: :current_bid, extractor: :price_extractor }
            }
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
              filters: [ { truncate_query_strings: true } ]
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
            extract: {
              { source: :grains,   extractor: :keyword },
              { source: :title,    extractor: :grains_extractor, progressive: true, shingle_terms: true },
              { source: :keywords, extractor: :grains_extractor, progressive: true, shingle_terms: true },
            },
            validate: {
              range: { gte: 1, lte: 500 }
            },
          },
          caliber: {
            extract: {
              { source: :caliber,  extractor: :caliber_extractor },
              { source: :title,    extractor: :caliber_extractor, progressive: true, shingle_terms: true },
              { source: :keywords, extractor: :caliber_extractor, progressive: true, shingle_terms: true },
            },
          },
          manufacturer: {
            extract: {
              { source: :manufacturer, extractor: :manufacturer_extractor },
              { source: :title,        extractor: :manufacturer_extractor, progressive: true, shingle_terms: true },
              { source: :keywords,     extractor: :manufacturer_extractor, progressive: true, shingle_terms: true },
            },
          },
        }
      }
    end

    def self.index_options
      {
        settings: {
          extraction: {
            stored_sources: [:title, :keywords] # it will store these, and only run each filter once on them
            sequence:       [:caliber, :manufacturer, :grains, :number_of_rounds]
            extractor: {
              caliber_extractor: {
                type:   :custom,
                filter: [:lowercase, :scrub_whitespace, :scrub_punctuation, :scrub_dots, :scrub_calibers, :restore_dots],
                synonyms: {
                  source:  ElasticTools::Synonyms.explicit_mappings(:caliber),
                  shingle: true
                }
                extract_terms: {
                  source: ElasticTools::Synonyms.calibers
                  terms:  :first # other options: :last, :most_popular, :least_popular, :cat_all
                }
              },
              grains_extractor: {
                type:   :custom,
                filter: [:lowercase, :scrub_whitespace, :scrub_punctuation, :scrub_grains],
              },
              price_extractor: { type: :price, currency: :usd, output: :cents },
            }
          },
        },
        mappings: {
          listing: deep_merge(index_mappings, stretched_mappings),
        }
      }
    end
  end
end

