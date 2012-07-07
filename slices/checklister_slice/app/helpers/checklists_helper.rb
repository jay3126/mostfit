module Merb::ChecklisterSlice::ChecklistsHelper
  def perform_link(role,checklist,parameter_hash)
    if ROLE_MAPPER[:performer].include?(role.to_s)

      link_to 'Respond to checklist', url(:checklister_slice_fill_in_checklist,checklist ,parameter_hash)
    end

  end

  def response_link(role,checklist)
    if checklist.responses.count>0
    if ROLE_MAPPER[:viewer].include?(role.to_s)
      link_to 'See all responses', url(:checklister_slice_view_checklist_responses,checklist)
    end
    else
"      No responses yet"
  end
  end


  def are_parameters_correct?(parameter_hash)
    if parameter_hash[:filler_record_id].nil? or parameter_hash[:filler_model].nil? parameter_hash[:target_entity_record_id].nil? or parameter_hash[:target_entity_model].nil?
       false
    else
      true
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