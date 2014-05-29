module StretchedTools
  module IndexMapping

    def self.index_properties
      {
        properties: {
          url: {
            validate: {
              uri: {
                scheme: :any,
                restrict_domain: true,
              }
            }
          },
          image_source: {
            filter: [ :truncate_query_strings ],
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
              keyword: {
                accept: ["Guns", "Ammunition", "Optics", "Accessories", "None"]
              }
            }
          },
          availability: {
            validate: {
              keyword: {
                accept: ["in_stock", "out_of_stock", "unknown"]
              }
            }
          },
          item_condition: {
            validate: {
              keyword: {
                accept: ["New", "Used", "Unknown"]
              }
            }
          },
          type: {
            validate: {
              keyword: {
                accept: ["RetailListing", "ClassifiedListing", "AuctionListing"]
              }
            }
          },
          grains: {
            validate: {
              range: { gte: 1, lte: 400 }
            },
            sources: [:keyword, :grains_analyzer]
          },
          number_of_rounds: {
            validate: {
              range: { gte: 1, lte: 100000 }
            },
            sources: [:keyword, :number_of_rounds_analyzer]
          },
          caliber: {
            validate: {
              keyword: { accept: ElasticTools::Synonyms.calibers }
            },
            sources: [:keyword, :caliber_extractor]
          },
          manufacturer: {
            validate: {
              keyword: { accept: ElasticTools::Synonyms.manufacturers }
            },
            sources: [:keyword, :manufacturer_extractor]
          },
        }
      }
    end

    def self.index_options
      {
        settings: {
          extraction: {
            extractor: {
              caliber: {
                type: :custom,
                tokenizer: :whitespace,
                filter: [:scrub_dots, :scrub_calibers, :restore_dots]
                extract: {
                  dictionary: ElasticTools::Synonyms.calibers,
                  terms: :first_match,
                  output: :shingled
                }
              },
            }
          }
        },
        mappings: {
          listing: deep_merge(index_mappings, stretched_mappings),
        }
      }
    end
  end
end

