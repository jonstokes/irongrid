module ProductDetails
  module Caliber
    def self.parse_category(text)
      # E.g. parse_category("Type: Rifle")
      # => { text: "type: rifle", keywords: ["rifle"] }
      ProductDetails::Parser.new.parse(text.try(:downcase), dictionaries.keys.map)
    end

    def self.lowercase_synonym_filter(text)
      # E.g. analyze("Caliber: .17 Aguila")
      # => "caliber: .17 pmc"
      return unless text
      str = text.dup.strip
      ElasticTools::Analyzer.analyze(str, analyzer: :product_terms)
    end

    def self.parse(text)
      # E.g. parse("caliber: .17 pmc")
      # => text: "caliber: .17 PMC", keywords: [".17 PMC"], category: => "rimfire"
      ProductDetails::Parser.new.parse_with_category(text, dictionaries)
    end

    def self.dictionaries
      ElasticTools::Synonyms.calibers
    end

    def self.analyze(term)
      ElasticTools::Analyzer.analyze(term, analyzer: :calibers)
    end
  end
end
