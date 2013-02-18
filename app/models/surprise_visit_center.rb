class SurpriseVisitCenter
  include DataMapper::Resource
  
  property :id, Serial
  property :staff_member, String
  property :value_date, Date
  property :3_members_late, Boolean	
  property :3_members_absent, Boolean
  property :leader_was_present_at_meeting, Boolean
  property :center_members_followed_procedures, Boolean
  property :field_office_followed_procedures, Boolean
  property :center_leaders_attendance_utdate, Boolean
  property :pbook_and_centers_uptdate, Boolean
  property :no_member_paind_any_add_money, Boolean
  property :all_claims_settled_no_pending, Boolean
  property :all_center_meeting_plcae_ntchgd, Boolean
  property :concern_about_center, Boolean
  property :file_update_with_previous_scvs, Boolean
  property :genreal_comments, Text 
  property :customer_comments,Text
  property :name_of_officer, String
  property :date , Date
  property :place, String



end
