class RenameGamificationScore < ActiveRecord::Migration
  def change
    drop_table :user_actions
    drop_table :gamification_scores

    create_table :gamification_rules do |t|
      t.string :action_service
      t.string :action_controller
      t.string :action_method
      t.string :action_attribute
      t.string :description
      t.integer :value, default: 0
    end

    create_table :user_actions do |t|
      t.references :user, foreign_key: true, null: false
      t.references :gamification_rule, foreign_key: true, null: false
      t.boolean :scheduled, default: false
      t.timestamps
      t.timestamp :scheduled_at
    end

    add_index(:gamification_rules, [:action_service, :action_controller, :action_method, :action_attribute], unique: true, name: "gIndex")

    create_table :gamification_results do |t|
      t.references :user, foreign_key: true, null: false
      t.integer :global_stats
      t.integer :month_stats
      t.integer :value, default: 0
      t.timestamp :updated_at
    end

    create_table :gamification_service_results do |t|
      t.references :gamification_result, foreign_key: true, null: false
      t.string :service
      t.integer :global_partial_result
      t.integer :month_partial_result
      t.timestamp :updated_at
    end

  end
end
