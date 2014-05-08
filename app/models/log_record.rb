# == Schema Information
#
# Table name: log_records
#
#  id         :integer          not null, primary key
#  data       :json             not null
#  agent      :string(255)      not null
#  jid        :string(255)      not null
#  archived   :boolean
#  created_at :datetime
#  updated_at :datetime
#

class LogRecord < ActiveRecord::Base
  include Retryable
  include Notifier
  include ConnectionWrapper

  attr_accessible :data, :jid, :agent, :archived

  scope :active, -> { where(:archived => [nil, false]) }

  def unarchive
    self.update_attribute(:archived, false)
  end

  def self.archive_all
    db do
      LogRecord.active.each do |record |
        record.update_attribute(:archived, true)
      end
    end
  end
end
