module ElasticTools
  module QueryPreParser
    def self.escape_query(text)
      # Escape special characters
      # http://lucene.apache.org/core/old_versioned_docs/versions/2_9_1/queryparsersyntax.html#Escaping Special Characters

      return unless text && !text.blank?
      str = text.dup
      escaped_characters = Regexp.escape('\\+-&|!(){}[]^~*?:/')
      str.gsub!(/([#{escaped_characters}])/, '\\\\\1')

      # Escape odd quotes
      quote_count = str.count '"'
      str.gsub!(/(.*)"(.*)/, '\1\"\3') if quote_count % 2 == 1
      str.strip.squeeze(" ")
    end
  end
end
