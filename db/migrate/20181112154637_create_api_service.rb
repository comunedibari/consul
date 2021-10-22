class CreateApiService < ActiveRecord::Migration
  def change
    create_table :api_services do |t|
      t.string :service_title
      t.string :service_url
      t.string :service_how
      t.string :service_summary
      t.references :setting, foreign_key: true, null:true
    end
  end
end
