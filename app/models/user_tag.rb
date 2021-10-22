class UserTag < ActiveRecord::Base

  belongs_to :user

  belongs_to :tag, class_name: 'ActsAsTaggableOn::Tag', foreign_key: 'tag_id'
  
  attr_accessor :selected

  def selected?
    self.selected
  end
 
end
