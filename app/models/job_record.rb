# == Schema Information
#
# Table name: job_records
#
#  id               :integer          not null, primary key
#  domain           :string(255)
#  links_crawled    :integer
#  pages_created    :integer
#  pages_deleted    :integer
#  complete         :boolean
#  listings_created :integer
#  listings_updated :integer
#  listings_deleted :integer
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  worker           :string(255)
#  listings_read    :integer
#  archived         :boolean
#  links_created    :integer
#  links_deleted    :integer
#

class JobRecord < ActiveRecord::Base
  include ConnectionWrapper
  include Retryable
  include Notifier

  attr_accessible :worker, :domain, :links_crawled, :pages_created, :pages_deleted, :complete, :listings_created, :listings_read, :listings_updated, :listings_deleted, :links_created, :links_deleted

  def self.append_or_create_job_record(opts)
    JobRecord.where(:worker => opts[:worker], :domain => opts[:domain], :complete => false).order("updated_at ASC").last || JobRecord.create(opts)
  end

  def self.archive_all
    db { JobRecord.where(:archived => [false, nil]).where("worker != 'UpdateListingsWorker'").update_all(:archived => true) }
  end
end
