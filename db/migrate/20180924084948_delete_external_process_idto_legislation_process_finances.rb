class DeleteExternalProcessIdtoLegislationProcessFinances < ActiveRecord::Migration
  def change
    def self.up
      add_column :legislation_process_finances, :external_process_id, :string
    end
  
    def self.down
      remove_column :legislation_process_finances, :external_process_id
    end
   
  end
end
