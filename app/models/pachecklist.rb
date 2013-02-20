class Pachecklist
  include DataMapper::Resource
  
  property :id, Serial
  property :answers, Text
  property :name, String
  property :date_of_audit, Date
  property :audit_period, String
  property :scv_perday, String
  property :meeting_attended_during_ap, String
  property :branch_management, String
  property :social_audit, String
  property :supervision, String
  property :positive1, Text
  property :postive2, Text
  property :positive3, Text
  property :deviation1, Text
  property :deviation2, Text
  property :deviation3, Text
  property :performed_by, String
  



  belongs_to :biz_location

  validates_with_method :scv_perday , :method => :scv_perday?
  validates_with_method :meeting_attended_during_ap , :method => :meeting_attended_during_ap?
  validates_with_method :branch_management , :method => :branch_management?
  validates_with_method :social_audit , :method => :social_audit?
  validates_with_method :supervision , :method => :supervision?

  def scv_perday?
   if scv_perday == "6" || scv_perday == "7" || scv_perday == "8" || scv_perday == "9" ||scv_perday == "10" || scv_perday == "0"
     return [true,"yes"]
   else
     return [false,"No"]
   end
  end
 
   def meeting_attended_during_ap?
   if meeting_attended_during_ap == "6" || meeting_attended_during_ap == "7" || meeting_attended_during_ap == "8" || meeting_attended_during_ap == "9" || meeting_attended_during_ap == "10" || meeting_attended_during_ap == "0"
     return [true,"yes"]
   else
     return [false,"No"]
   end
  end
 
   def branch_management?
   if branch_management == "6" || branch_management == "7" || branch_management == "8" || branch_management == "9" || branch_management == "10" || branch_management == "0"
     return [true,"yes"]
   else
     return [false,"No"]
   end
  end
  
    def social_audit?
   if social_audit == "6" || social_audit == "7" || social_audit == "8" || social_audit == "9" || social_audit == "10" || social_audit == "0"
     return [true,"yes"]
   else
     return [false,"No"]
   end
  end 
  
    def supervision?
   if supervision == "6" || supervision == "7" || supervision == "8" || supervision == "9" || supervision == "10" || supervision == "0"
     return [true,"yes"]
   else
     return [false,"No"]
   end
  end 
    
end
 