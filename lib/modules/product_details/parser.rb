module ProductDetails
  class Parser
    def parse(text, keyword_list)
      # Expects lowercase text, and will normalize case to keywords list
      # E.g. parse("foo bar baz", ["Foo", "Bar"])
      # => { text: "Foo Bar baz", keywords: ["Foo", "Bar"] }
      return unless text && !text.blank?
      str = text.dup
      keywords = []

      keyword_list.each do |keyword|
        keyword_shingle = keyword.gsub(" ", "_")
        keyword_shingle_regexp_string = keyword_shingle.gsub(/(\s|_)/,'(\s|_)')
        keyword_shingle_regexp = Regexp.new(keyword_shingle_regexp_string, true)
        keyword_regexp_string = "\\A#{keyword_shingle_regexp_string}\\s+|\\s+#{keyword_shingle_regexp_string}\\s+|\\s+#{keyword_shingle_regexp_string}\\z|\\A#{keyword_shingle_regexp_string}\\z"
        keyword_regexp = Regexp.new(keyword_regexp_string, true)
        if str[keyword_regexp]
          str.gsub!(keyword_regexp) do |match|
            match.sub!(keyword_shingle_regexp, keyword_shingle)
          end
          keyword_index = str.index(keyword_shingle)
          keywords << [keyword_index, keyword]
        end
      end
      { text: str, keywords: keywords.sort.map(&:last).map { |kw| kw.gsub("_", " ") if kw.is_a?(String) } }
    end

    def parse_with_category(text, dictionaries)
      # Expects lowercase text, and will normalize case to keywords list
      # Also will categorize given a dictionary hash
      return unless text && !text.blank?
      results = { text: text.dup}
      keywords = []
      category = nil

      dictionaries.each_pair do |category_name, keyword_list|
        results = parse(results[:text], keyword_list)
        if results[:keywords].any?
          keywords += results[:keywords]
          category ||= category_name
        end
      end

      { text: results[:text], keywords: keywords, category: category }
    end
  end
end
