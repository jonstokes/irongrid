module ProductDetails
  module Manufacturer
    def self.lowercase_synonym_filter(text)
      return unless text
      str = text.dup.strip
      ElasticTools::Analyzer.analyze(str, analyzer: :product_terms)
    end

    def self.parse(text)
      ProductDetails::Parser.new.parse(text, dictionary)
    end

    def self.dictionary
      ElasticTools::Synonyms.manufacturers
    end

    def self.analyze(term)
      ElasticTools::Analyzer.analyze(term, analyzer: :manufacturers)
    end
  end
end
