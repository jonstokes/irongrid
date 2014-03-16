# == Schema Information
#
# Table name: service_records
#
#  id                    :integer          not null, primary key
#  service               :string(255)
#  main_thread_status    :string(255)
#  tracker_thread_status :string(255)
#  batch_status          :text
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  host                  :string(255)
#  thread_error          :text
#  tracker_error         :text
#  archived              :boolean
#

class ServiceRecord < ActiveRecord::Base
  include ConnectionWrapper
  include Retryable
  include Notifier

  attr_accessible :batch_status, :main_thread_status, :tracker_thread_status, :service, :thread_error, :tracker_error, :host

  def archived?
    !!self.archived
  end

  def batch_status_update(string)
    string << " [#{Time.now}]"
    db { self.update_attribute(:batch_status, string) }
  end

  def self.archive_all
    db do
      ServiceRecord.where(:archived => [false, nil]).each do |record |
        record.update_attribute(:archived, true)
      end
    end
  end
end
