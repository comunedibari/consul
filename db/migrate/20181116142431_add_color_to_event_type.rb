class AddColorToEventType < ActiveRecord::Migration
  def up
    add_column :event_types, :event_color, :text, defualt: "#0000ff"
    add_column :event_types, :creable, :integer, defualt: 0
  end

  def down
    remove_column :event_types, :event_color
    remove_column :event_types, :creable
  end
end
