module Ahoy
  class Event < ActiveRecord::Base
    self.table_name = "ahoy_events"

    belongs_to :visit
    belongs_to :user
    belongs_to :author, -> { with_hidden }, class_name: 'User', foreign_key: 'author_id'
  end
end
