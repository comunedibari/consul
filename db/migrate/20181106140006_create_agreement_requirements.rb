class CreateAgreementRequirements < ActiveRecord::Migration
  def change
    create_table :agreement_requirements do |t|
      t.belongs_to :collaboration_agreement, index: true, foreign_key: true
      t.string :title
      t.date :start_date
    end
  end
end
