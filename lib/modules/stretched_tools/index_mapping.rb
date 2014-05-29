module StretchedTools
  module IndexMapping

    def self.index_properties
      {
        properties: {
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
            extract: {
              { source: :price, extractor: :price_extractor }
            }
          },
          sale_price_in_cents: {
            extract: {
              { source: :sale_price, extractor: :price_extractor }
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
          type: {
            validate: {
              presence: true,
              keyword: {
                accept: ["RetailListing", "ClassifiedListing", "AuctionListing"]
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
          grains: {
            extract: {
              { source: :grains,   extractor: :keyword},
              { source: :title,    extractor: :grains_extractor},
              { source: :keywords, extractor: :grains_extractor},
            },
            validate: {
              range: { gte: 1, lte: 500 }
            },
          },
          caliber: {
            extract: {
              { source: :caliber,  extractor: :caliber_extractor},
              { source: :title,    extractor: :caliber_extractor},
              { source: :keywords, extractor: :caliber_extractor},
            },
          },
        }
      }
    end

    def self.index_options
      {
        settings: {
          extraction: {
            extractor: {
              caliber_extractor: {
                type:            :custom,
                filter:          [:lowercase, :scrub_whitespace, :scrub_punctuation, :scrub_dots, :scrub_calibers, :restore_dots, :caliber_synonym],
              },
              grains_extractor: {
                type:            :custom,
                filter:          [:lowercase, :scrub_whitespace, :scrub_punctuation, :scrub_grains],
              },
              price_extractor: { type: :price, currency: :usd, output: :cents },
            }
          },
          filters: {
            caliber_synonym: {
              type: :synonym,
              synonyms: ElasticTools::Synonyms.explicit_mappings(:caliber)
              terms_vector: :first # other options: :last, :most_popular, :least_popular
            },
          }
        },
        mappings: {
          listing: deep_merge(index_mappings, stretched_mappings),
        }
      }
    end
  end
end

