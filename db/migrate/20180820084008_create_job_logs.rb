class CreateJobLogs < ActiveRecord::Migration
  def change
    create_table :job_logs do |t|
      t.string  :jid, index: true
      t.integer :state
      t.string :resource
      t.string :resource_type
      t.timestamps
    end
  end
end