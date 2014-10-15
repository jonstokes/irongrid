module ElasticTools
  module IndexMapping

    def self.generate(index_name)
      opts = index_options
      Tire.index index_name do
        create(opts)
      end
    end

    def self.index_properties
      {
        properties: {
          id:               { type: :integer, index: :no },
          title: {
            type: :object,
            properties: {
              title:        { type: :string, boost: 10 },
              scrubbed:     { type: :string, analyzer: :scrubbed_text, boost: 4 },
              normalized:   { type: :string, analyzer: :keyword },
              autocomplete: { type: :string, analyzer: :autocomplete }
            }
          },
          description:           { type: :string,                           boost: 4 },
          keywords:              { type: :string,                           boost: 5 },
          url:                   { type: :string, analyzer: :keyword },
          type:                  { type: :string, analyzer: :keyword },
          item_condition:        { type: :string, analyzer: :keyword },
          availability:          { type: :string, analyzer: :keyword },
          image:                 { type: :string, analyzer: :keyword },
          seller_name:           { type: :string, analyzer: :keyword },
          seller_domain:         { type: :string, analyzer: :keyword },
          created_at:            { type: :date },
          updated_at:            { type: :date },
          auction_ends:          { type: :date },
          current_price_in_cents: { type: :integer },
          price_in_cents:         { type: :integer },
          sale_price_in_cents:    { type: :integer },
          buy_now_price_in_cents: { type: :integer },
          current_bid_in_cents:   { type: :integer },
          minimum_bid_in_cents:   { type: :integer },
          reserve_in_cents:       { type: :integer },
          discount_in_cents:      { type: :integer },
          discount_percent:       { type: :integer },
          discount_in_cents_with_shipping: { type: :integer },
          discount_percent_with_shipping:  { type: :integer },
          shipping_cost_in_cents:          { type: :integer },
          weight_in_pounds:                { type: :float },
          price_on_request:      { type: :string, analyzer: :keyword },
          upc:                   { type: :string, analyzer: :keyword },
          mpn:                   { type: :string, analyzer: :keyword },
          sku:                   { type: :string, analyzer: :keyword },
          city:                  { type: :string, analyzer: :keyword },
          state:                 { type: :string, analyzer: :keyword },
          state_code:            { type: :string, analyzer: :keyword },
          country:               { type: :string, analyzer: :keyword },
          country_code:          { type: :string, analyzer: :keyword },
          zip_code:              { type: :string, analyzer: :keyword },
          postal_code:           { type: :string, analyzer: :keyword },
          coordinates: {
            type: :geo_point,
            lat_lon: true
          },
          category1: {
            properties: {
              category1:           { type: :string, analyzer: :category_keyword },
              classification_type: { type: :string, analyzer: :keyword },
              score:               { type: :integer }
            }
          },
          caliber_category: {
            properties: {
              caliber_category:    { type: :string, analyzer: :category_keyword },
              classification_type: { type: :string, analyzer: :keyword },
            }
          },
          manufacturer: {
            properties: {
              manufacturer:        { type: :string, analyzer: :keyword },
              classification_type: { type: :string, analyzer: :keyword }
            }
          },
          caliber: {
            properties: {
              caliber:             { type: :string, analyzer: :keyword },
              classification_type: { type: :string, analyzer: :keyword }
            }
          },
          grains: {
            properties: {
              grains:              { type: :integer },
              classification_type: { type: :string, analyzer: :keyword }
            }
          },
          number_of_rounds: {
            properties: {
              number_of_rounds:    { type: :integer },
              classification_type: { type: :string, analyzer: :keyword }
            },
          price_per_round_in_cents: { type: :integer },
          price_per_round_in_cents_with_shipping: { type: :integer },
          current_price_in_cents_with_shipping: { type: :integer },
          },
        }
      }
    end

    def self.index_options
      {
        settings: {
          analysis: {
            analyzer: {
              default:  {
                type:      :custom,
                tokenizer: :standard,
                filter:    [ :standard, :lowercase, :listing_synonym, :english_snowball ]
              },
              category_keyword: {
                type: :custom,
                tokenizer: :keyword,
                filter: :lowercase
              },
              scrubbed_text: {
                type:       :custom,
                tokenizer:  :whitespace,
                filter:     [ :lowercase, :listing_synonym ]
              },
              autocomplete: {
                type:      :custom,
                tokenizer: :whitespace,
                filter:    [ :lowercase, :listing_synonym, :edgengram ]
              },
              product_terms: {
                type:      :custom,
                tokenizer: :whitespace,
                filter:    [ :lowercase, :product_synonym ]
              },
              calibers: {
                type:      :custom,
                tokenizer: :whitespace,
                filter:    [ :lowercase, :caliber_synonym ]
              },
              manufacturers: {
                type:      :custom,
                tokenizer: :whitespace,
                filter:    [ :lowercase, :manufacturer_synonym ]
              }
            },
            filter: {
              edgengram: {
                type: "edgeNGram",
                min_gram: 2,
                max_gram: 15
              },
              listing_synonym: {
                type: :synonym,
                synonyms: ElasticTools::Synonyms.equivalent_synonyms
              },
              product_synonym: {
                type: :synonym,
                synonyms: ElasticTools::Synonyms.explicit_mappings
              },
              caliber_synonym: {
                type: :synonym,
                synonyms: ElasticTools::Synonyms.explicit_mappings(:caliber)
              },
              manufacturer_synonym: {
                type: :synonym,
                synonyms: ElasticTools::Synonyms.explicit_mappings(:manufacturer)
              },
              english_snowball: {
                type: :snowball,
                language: "English"
              }
            }
          }
        },
        mappings: {
          auction_listing:    index_properties,
          classified_listing: index_properties,
          retail_listing:     index_properties
        }
      }
    end
  end
end
