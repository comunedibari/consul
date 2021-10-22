class CreateLevelActivitiesType < ActiveRecord::Migration
  def change
    create_table :level_activities_types do |t|
      t.string  "name"
    end
  end
end
