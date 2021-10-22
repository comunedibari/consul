module Slottable
  extend ActiveSupport::Concern

  included do
    has_many :event_slots #, dependent: :destroy
    accepts_nested_attributes_for :event_slots, allow_destroy: true
  end

  module ClassMethods

  end
  
end