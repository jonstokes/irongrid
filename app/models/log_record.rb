class LogRecord < ActiveRecord::Base
  include Retryable
  include Notifier
  include ConnectionWrapper

  attr_accessible :data, :jid, :agent, :archived

  scope :active, -> { where(:archived => [nil, false]) }

  def self.archive_all
    db do
      JobRecord.where(:archived => [false, nil]).each do |record |
        record.update_attribute(:archived, true)
      end
    end
  end
end
