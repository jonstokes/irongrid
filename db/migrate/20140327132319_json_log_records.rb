class JsonLogRecords < ActiveRecord::Migration
  def change
    create_table :log_records do |t|
      t.json    :data,     null: false
      t.string  :agent,    null: false
      t.string  :jid,      null: false
      t.boolean :archived

      t.timestamps
    end
    add_index :log_records, [:jid], name: :index_log_records_on_jid, unique: true, using: :btree
  end
end
