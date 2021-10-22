class CreateSocialContents < ActiveRecord::Migration
  def change
    create_table :social_contents do |t|

      t.references  :sociable, polymorphic: true, index: true
      t.boolean     :social_access , default: true
      t.datetime    :created_at, null: false
      t.datetime    :updated_at

    end
    add_index :social_contents, [ :sociable_type, :sociable_id], name: "access_socials"
  end
end
