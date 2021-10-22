class ReportingType < ActiveRecord::Base
  
    has_many :reportings

    belongs_to :institution, foreign_key: 'institution_id'

end
