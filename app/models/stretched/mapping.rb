module Stretched
  class Mapping < Registration
    attr_reader :tokenizer

    def initialize(opts)
      super(opts.merge(type: "Mapping"))
      @tokenizer = Tokenizer::Tokenizer.new
    end

    def reduce(text)
      tokens = tokenize(text)
      return unless term = @data.detect do |term, mapping|
        tokenize_mapping(term, mapping).detect do |term_tokens|
          next unless offset = tokens.index { |t| t == term_tokens.first }
          last_term = offset + (term_tokens.size - 1)
          next unless tokens[offset..last_term].map(&:downcase) == term_tokens.map(&:downcase)
          tokens.slice!(offset..last_term)
          true
        end
      end.try(:first)

      { term: term, tokens: tokens }
    end

    def has_term?(term); @data.has_key?(term.to_s); end
    def terms; @data.keys; end
    def [](term); @data[term.to_s]; end

    #private

    def tokenize_mapping(term, mapping)
      ary = [term] + (mapping || [])
      ary.map! { |term| tokenize(term) }
      ary.sort { |a, b| b.size <=> a.size }
    end

    def tokenize(str)
      tokenizer.tokenize(str).reject { |t| t.empty? }
    end

    def untokenize(tokens)
      str = ""
      tokens.each { |t| str << "#{t} " }
      str.strip
    end
  end
end
