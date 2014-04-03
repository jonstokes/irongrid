class DropLegacyRecords < ActiveRecord::Migration
  def change
    drop_table :job_records
    drop_table :service_records
  end
end
