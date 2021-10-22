class AddExternalUrlToLegislationProcessWorks < ActiveRecord::Migration
  def change
    add_column :legislation_process_works, :external_url, :string
  end
end
