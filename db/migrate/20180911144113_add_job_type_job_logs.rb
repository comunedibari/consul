class AddJobTypeJobLogs < ActiveRecord::Migration
  def change
    add_column :job_logs, :job_type, :string
  end
end
