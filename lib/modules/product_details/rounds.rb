module ProductDetails
  module Rounds
    def self.parse(text)
      return unless text && !text.strip.blank?
      str = text.dup
      rounds = str[/\d{1,5} round/i] ? str[/\d{1,5} round/i].delete(" rounds").delete(" round").to_i : nil
      { text: str, keywords: [rounds].compact }
    end
  end
end
