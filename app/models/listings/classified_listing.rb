# == Schema Information
#
# Table name: listings
#
#  id           :integer          not null, primary key
#  digest       :string(255)      not null
#  type         :string(255)      not null
#  url          :text             not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  inactive     :boolean
#  update_count :integer
#  geo_data_id  :integer
#  item_data    :json
#  site_id      :integer
#

class ClassifiedListing < Listing
  index_name superclass.index_name
end
