module ProductDetails
  module Scrubber
    def self.scrub(text, *opts)
      return unless text.present?
      str = text.dup
      str = scrub_inches(text) if opts.include?(:inches)
      str = scrub_grains(str) if opts.include?(:grains)
      str = scrub_rounds(str) if opts.include?(:rounds)

      str = scrub_dot(str) if opts.include?(:caliber)
      str = scrub_calibers(str) if opts.include?(:caliber)
      str = restore_dot(str) if opts.include?(:caliber)

      str = scrub_color(str) if opts.include?(:color)
      str = scrub_punctuation(str) if opts.include?(:punctuation)
      str
    end

    def self.scrub_all(text)
      return unless text.present?
      scrub(text, :inches, :grains, :rounds, :caliber, :punctuation)
    end

    def self.scrub_punctuation(text)
      return unless text && !text.blank?
      str = " #{text} "
      str.gsub!(/\d\,\d{3}(\D)/) do |match|
        match.sub!(",", "")
      end
      str.gsub!(/\,|\!|\;/, " ")
      str.strip.squeeze(" ")
    end

    def self.scrub_inches(text)
      return unless text && !text.blank?
      str = " #{text} "

      str.gsub!(/\d{1,2}+\s{0,1}\"\.?\,?\s+/i) do |match|
        match.sub!(/\s{0,1}\"(\s?|\,?)/i, " inch ")
      end

      str.gsub!(/\d{1,2}+\s{0,1}in\.?\,?\s+/i) do |match|
        match.sub!(/\s{0,1}in(\s?|\,?)/i, " inch ")
      end

      str.gsub!(/\s+/," ")
      str.try(:strip!)
      str
    end

    def self.scrub_color(text)
      return unless text && !text.blank?
      str = " #{text} "

      str.gsub!(/\s+blk\s+/i, " black ")
      str.gsub!(/\s+slv\s+/i, " silver ")
      str.gsub!(/\s+/," ")
      str.strip.squeeze(" ")
    end

  end
end
