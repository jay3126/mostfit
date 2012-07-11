module Merb::ChecklisterSlice::ChecklistsHelper
  def perform_link(role, checklist, parameter_hash)
    if ROLE_MAPPER[checklist.checklist_type.name][:performer].include?(role.to_s)

      link_to 'Respond to checklist', url(:checklister_slice_fill_in_checklist, checklist, parameter_hash), :class => "greenButton"
    end

  end

  def response_link(role, checklist, referral_url)
    if checklist.responses.count>0
      if ROLE_MAPPER[checklist.checklist_type.name][:viewer].include?(role.to_s)
        link_to 'See all responses', url(:checklister_slice_view_checklist_responses, checklist, :referral_url => referral_url), :class => "greenButton"
      else
        "<span class=''>Not Authorized</span>"
      end

    else
      "<span class=''>No responses yet</span>"
    end
  end


  def verify_parameters(parameter_hash)
    if parameter_hash[:staff_name].blank? or parameter_hash[:staff_id].blank?
      raise StaffNotFoundException, "Staff Member Parameters are wrong."

    elsif parameter_hash[:target_entity_name].blank? or parameter_hash[:target_entity_type].blank? or parameter_hash[:target_entity_id].blank?
      raise TargetEntityNotFoundException, "Target entity parameters are wrong."
    elsif parameter_hash[:loc1_type].blank? or parameter_hash[:loc1_name].blank? or parameter_hash[:loc1_id].blank?
      raise LocationNotFoundException, "Location Parameters are wrong."
    elsif parameter_hash[:referral_url].blank?
      raise UrlNotFoundException, "Referral URL is wrong."
    end
  end

  def convert_into_constant(required_string)
    if required_string.include?("_")
      required_string.camelcase
    else
      required_string.capitalize
    end
  end

end