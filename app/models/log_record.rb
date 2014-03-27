class LogRecord < ActiveRecord::Base
  include Retryable
  include Notifier
  include ConnectionWrapper

  attr_accessible :data, :jid, :agent, :archived

  scope :active, -> { where(:archived => [nil, false]) }
end
