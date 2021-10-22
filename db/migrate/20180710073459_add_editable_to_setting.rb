class AddEditableToSetting < ActiveRecord::Migration
  def change
    add_column :settings, :editable, :boolean
  end
end
