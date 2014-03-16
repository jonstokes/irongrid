class MetadataTable
  METADATA_ATTRIBUTES = [:caliber, :caliber_category, :manufacturer, :grains, :number_of_rounds]

  attr_reader :table

  def initialize
    @table = {}
    METADATA_ATTRIBUTES.each do |attr|
      table[attr] = {}
    end
  end

  def update(row)
    table[row[:attribute]][row[:source]] = row[:content]
  end

  def final_value(attr)
    @table[attr][:raw] || @table[attr][:title] || @table[attr][:keywords]
  end

  def classification_type(attr)
    return "hard" if @table[attr][:raw]
    return "metadata" if @table[attr][:title] || @table[attr][:keywords]
  end
end
