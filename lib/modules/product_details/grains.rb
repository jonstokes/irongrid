module ProductDetails
  module Grains
    def self.parse(text)
      return unless text && !text.strip.blank?
      str = text.dup
      grains = str[/\d{2,5} grain/i] ? str[/\d{2,5} grain/i].delete(" grain").to_i : nil
      { text: text, keywords: [grains].compact }
    end
  end
end
