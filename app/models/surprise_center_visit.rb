class SurpriseCenterVisit
  include DataMapper::Resource
  
  property :id, Serial
  property :staff_member, String
  property :value_date, Date
  property :members_late, String	
  property :members_absent, String
  property :leader_was_present_at_meeting, String
  property :center_members_followed_procedures, String
  property :field_office_followed_procedures, String
  property :center_leaders_attendance_utdate, String
  property :pbook_and_centers_uptdate, String
  property :no_member_paind_any_add_money, String
  property :all_claims_settled_no_pending, String
  property :all_center_meeting_plcae_ntchgd, String
  property :concern_about_center, String
  property :file_update_with_previous_scvs, String
  property :genreal_comments, Text 
  property :customer_comments, Text
  property :name_of_officer, String
  property :date , Date
  property :place, String


end
