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
            }
          },
          number_of_rounds: {
            validate: {
              range: { gte: 1, lte: 100000 }
            }
          },
          caliber: {
            analyzer: :calibers
          },
          manufacturer: {
            analyzer: :manufacturers
          },
          grains: {
            analyzer: :grains
          },
          number_of_rounds: {
            analyzer: :number_of_rounds
          },
        }
      }
    end

    def self.index_options
      {
        settings: {
          analysis: {
            analyzer: {
              caliber: {
                type: :custom,
                tokenizer: :whitespace,
                filter: [:scrub_dots, :scrub_calibers, :restore_dots]
                extract: {
                  dictionary: ElasticTools::Synonyms.calibers,
                  terms: :first_match,
                  output: :normalized
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

