class Institution < ActiveRecord::Base
    include Filterable
  
    has_many :reporting_types


end
