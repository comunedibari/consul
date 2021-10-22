class Legislation::ProcessTypology < ActiveRecord::Base
  has_many :process, class_name: 'Legislation::Process'

  validates :name, presence: true, :uniqueness => {:case_sensitive => false}
end
