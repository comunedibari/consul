class CreateEventContents < ActiveRecord::Migration
  def change
    create_table :event_contents do |t|
      t.references :eventable, polymorphic: true, index: true
    end
    add_index :event_contents, [ :eventable_type, :eventable_id], name: "access_event_contents"
  end  
end
