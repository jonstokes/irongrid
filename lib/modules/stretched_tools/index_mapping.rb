module StretchedTools
  module IndexMapping

    def self.index
      {
        settings: {
          iron_grid: settings,
        },
        mappings: {
          listing: listing_mapping,
          feed: feed_mapping
        },
        adapters: {
          page_adapter: page_adapter,
          feed_adapter: feed_adapter
        }
      }
    end

    def self.settings
      {
        properties: {
          filters: {
            extract_caliber: {
              type: :extractor,
              dictionary: :caliber_terms,
              output: :first
            },
            caliber_synonyms: {
              type: :synonym,
              synonyms: ElasticTools::Synonyms.explicit_mappings(:caliber)
            },
            extract_manufacturer: {
              type: :extractor,
              dictionary: :manufacturer_terms,
              output: :first
            },
            manufacturer_synonyms: {
              type: :synonym,
              synonyms: ElasticTools::Synonyms.explicit_mappings(:manufacturer)
            },
          },
          dictionaries: {
            caliber_terms: ElasticTools::Synonyms.calibers,
            manufacturer_terms: ElasticTools::Synonyms.manufacturers,
            classification_types: ["hard", "soft", "metadata", "fall_through"]
          },
          analyzers: {
            analyzer: {
              caliber_analyzer: {
                type:   :custom,
                filter: [:lowercase, :scrub_whitespace, :scrub_punctuation, :scrub_dots, :scrub_calibers, :restore_dots, :caliber_synonyms, :extract_caliber],
              },
              manufacturer_analyzer: {
                type:   :custom,
                filter: [:lowercase, :scrub_whitespace, :scrub_punctuation, :manufacturer_synonyms, :extract_manufacturer],
              },
              grains_analyzer: {
                type:   :custom,
                filter: [:lowercase, :scrub_whitespace, :scrub_punctuation, :scrub_grains],
              },
              number_of_rounds_analyzer: {
                type:   :custom,
                filter: [:lowercase, :scrub_whitespace, :scrub_punctuation, :scrub_rounds],
              },
              price_analyzer: { type: :usd_to_cents },
            }
          },
        },
      }
    end

    def self.listing_mapping
      {
        properties: {
          type: {
            type: :string,
            validate: {
              presence: true,
              keyword: {
                accept: ["RetailListing", "ClassifiedListing", "AuctionListing"]
              }
            }
          },
          title: {
            type: :object,
            properties: {
              title:        { type: :string },
              scrubbed:     { type: :string },
              normalized:   { type: :string },
              autocomplete: { type: :string }
            },
            validate: { presence: true },
          },
          description: { type: :string },
          keywords: { type: :string },
          url: {
            type: :string,
            validate: {
              presence: true,
              uri: {
                scheme: :any,
                restrict_domain: true,
              }
            }
          },
          seller_name:    { type: :string },
          seller_domain:  { type: :string },
          auction_ends:   { type: :date },
          price_in_cents: {
            type: :integer,
            analyze: { source: :price, analyzer: :price_analyzer }
          },
          sale_price_in_cents: {
            type: :integer,
            analyze: { source: :sale_price, analyzer: :price_analyzer }
          },
          buy_now_price_in_cents: {
            type: :integer,
            analyze: { source: :buy_now_price, analyzer: :price_analyzer }
          },
          reserve_in_cents: {
            type: :integer,
            analyze: { source: :reserve, analyzer: :price_analyzer }
          },
          minimum_bid_in_cents: {
            type: :integer,
            analyze: { source: :minimum_bid, analyzer: :price_analyzer }
          },
          current_bid_in_cents: {
            type: :integer,
            analyze: { source: :current_bid, analyzer: :price_analyzer }
          },
          price_on_request: { type: :string },
          item_location:    { type: :string },
          availability: {
            type: :string,
            validate: {
              presence: true,
              keyword: {
                accept: ["in_stock", "out_of_stock", "unknown"]
              }
            }
          },
          item_condition: {
            type: :string,
            validate: {
              presence: true,
              keyword: {
                accept: ["New", "Used", "Unknown"]
              }
            }
          },
          image: {
            type: :string,
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
            properties: {
              category1: {
                type: :string,
                validate: {
                  keyword: {
                    accept: ["Ammunition", "Optics", "Accessories", "Guns", "None"]
                  }
                }
              }
            }
          },
          caliber_category: {
            properties: {
              caliber_category: {
                type: :string,
                validate: {
                  keyword: {
                    accept: ["Rimfire", "Shotgun", "Rifle", "Handgun"]
                  }
                }
              }
            }
          },
          caliber: {
            properties: {
              caliber: {
                type: :string,
                analyze: { source: :caliber,  analyzer: :caliber_analyzer },
              }
            }
          },
          manufacturer: {
            properties: {
              manufacturer: {
                type: :string,
                analyze: { source: :manufacturer, analyzer: :manufacturer_analyzer },
              }
            }
          },
          grains: {
            properties: {
              grains: {
                type: :integer,
                analyze: { source: :grains, analyzer: :grains_analyzer },
                validate: {
                  range: { gte: 1, lte: 500 }
                },
              },
            }
          },
          number_of_rounds: {
            properties: {
              number_of_rounds: {
                type: :integer,
                analyze: { source: :number_of_rounds, analyzer: :number_of_rounds_analyzer },
                validate: {
                  range: { gte: 1 }
                },
              }
            }
          },
        }
      }
    end

    def self.feed_mapping
      {
        properties: {
          product_links: {
            type: :array,
            validate: {
              allow_empty: true,
            },
            array_element: {
              type: :string,
              validate: {
                uri: {
                  scheme: :any,
                  restrict_domain: true,
                }
              }
            }
          },
        }
      }
    end
  end
end

