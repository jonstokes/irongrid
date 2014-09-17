Stretched::Extension.define do
  extension "extraction" do

    def extract_grains(text)
      return unless text.try(:present?)
      str = " #{text} "
      return unless grains = str[/\d+(\s{0,1}|\-)(gr|grn|grain)s?\.?\,?\s+/i]
      grains = grains[/\d+/]
      grains.present? ? grains : nil
    end

    def extract_number_of_rounds(text)
      return unless text.try(:present?)
      str = " #{text} "
      return unless rounds = str[/[0-9]+(\,[0-9]+)?\W{0,3}ro?u?n?ds?/i] ||
        str[/box\s+of\s+[0-9]+(\,[0-9]+)?\W/i] ||
        str[/[0-9]+(\,[0-9]+)?\W{0,3}(per|\/)\s?bo?x/i]
      r = rounds[/[0-9]+(\,[0-9]+)?/]
      r.present? ? r.delete(",") : nil
    end

    def extract_manufacturer(text)
      # pending
    end

    def extract_calibers(text)
      # pending
    end
  end
end
