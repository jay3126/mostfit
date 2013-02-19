class Pachecklist
  include DataMapper::Resource
  
  property :id, Serial
  property :answers, Text
  property :name, String
  property :date_of_audit, Date
  property :audit_period, String
  property :scv_perday, Integer
  property :meeting_attended_during_ap, Integer
  property :branch_management, Integer
  property :social_audit, Integer
  property :supervision, Integer
  property :positive1, Text
  property :postive2, Text
  property :positive3, Text
  property :deviation1, Text
  property :deviation2, Text
  property :deviation3, Text
  property :performed_by, String
  



  belongs_to :biz_location
  
end
 
