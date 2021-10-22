class DropAndCreateGamificationServiceResults < ActiveRecord::Migration
  def up
    drop_table :gamification_service_results

    create_table :gamification_service_results do |t|
      t.references :user, foreign_key: true, null: false
      t.string :service
      t.integer :global_partial_result
      t.integer :month_partial_result
      t.timestamp :updated_at
    end
  end
  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
