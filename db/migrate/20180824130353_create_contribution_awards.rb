class CreateContributionAwards < ActiveRecord::Migration
  def change
    create_table :contribution_awards do |t|
      t.text :contribution_award
      t.integer :score
      t.string :code
    end
  end
end
