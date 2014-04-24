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
