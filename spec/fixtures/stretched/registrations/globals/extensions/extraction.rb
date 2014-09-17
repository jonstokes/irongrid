Stretched::Extension.define do
  extension "extraction" do

    def extract_grains(attribute, instance)
      return unless instance[attribute].try(:present?)
      str = " #{instance[attribute]} "
      return unless grains = str[/\d+(\s{0,1}|\-)gr\.?\,?\s+/i]
      grains = grains[/\d+/]
      grains.present? ? grains : nil
    end

    def extract_number_of_rounds(attribute, instance)
      return unless instance[attribute].try(:present?)
      str = " #{instance[attribute]} "
      return unless rounds = str[/[0-9]+(\,[0-9]+)?\W{0,3}ro?u?n?ds?/i] ||
        str[/box\s+of\s+[0-9]+(\,[0-9]+)?\W/i] ||
        str[/[0-9]+(\,[0-9]+)?\W{0,3}(per|\/)\s?bo?x/i]
      rounds = rounds[/[0-9]+(\,[0-9]+)?/]
      rounds.present? ? rounds : nil
    end

  end
end
