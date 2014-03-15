module ElasticTools
  module Analyzer
    @@index = Tire::Index.new(Listing.index_name)

    def self.analyze(term, opts={})
      return if term.try(:empty?)
      options = { analyzer: :product_terms}.merge!(opts)
      return unless results = @@index.analyze_with_local(term, {analyzer: options[:analyzer]})
      token_list = results["tokens"]

      stack = Stack.new
      stack.push({})
      token_list.each do |token|
        st = stack.peek
        stack.push(token)
        next if st.empty? || (token["type"] != "SYNONYM")
        stack.swap if (st["position"] == token["position"]) && (st["type"] == "word")
        stack.pop if (st["token"].downcase == token["token"].downcase)
      end
      token_list = stack.elements.select { |token| token.is_a? Hash }.map { |token| "#{token['token']} "}.compact

      return token_list.first.strip if token_list.size == 1
      token_list.reduce(:+).try(:strip)
    end
  end
end
