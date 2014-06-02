module StretchedTools
  module IndexMapping


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
            classification_types: {
              type: :dictionary,
              dictionary: ["hard", "soft", "metadata", "fall_through"]
            }
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

    def self.listing_schema
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
            extract: { source: :price, extractor: :price_extractor }
          },
          sale_price_in_cents: {
            type: :integer,
            extract: { source: :sale_price, extractor: :price_extractor }
          },
          buy_now_price_in_cents: {
            type: :integer,
            extract: { source: :buy_now_price, extractor: :price_extractor }
          },
          reserve_in_cents: {
            type: :integer,
            extract: { source: :reserve, extractor: :price_extractor }
          },
          minimum_bid_in_cents: {
            type: :integer,
            extract: { source: :minimum_bid, extractor: :price_extractor }
          },
          current_bid_in_cents: {
            type: :integer,
            extract: { source: :current_bid, extractor: :price_extractor }
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
                extract: { source: :caliber,  extractor: :caliber_extractor },
              }
            }
          },
          manufacturer: {
            properties: {
              manufacturer: {
                type: :string,
                extract: { source: :manufacturer, extractor: :manufacturer_extractor },
              }
            }
          },
          grains: {
            properties: {
              grains: {
                type: :integer,
                extract: { source: :grains, extractor: :grains_extractor },
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
                extract: { source: :number_of_rounds, extractor: :number_of_rounds_extractor },
                validate: {
                  range: { gte: 1 }
                },
              }
            }
          },
        }
      }
    end

    def self.feed_schema
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

