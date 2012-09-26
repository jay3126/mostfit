# This file is here so slice can be testing as a stand alone application.

Merb::Router.prepare do
  resources :rejection_reasons
  resources :dropdownpoint_fillings
  resources :dropdownpoints
  resources :responses
  #resources :responses, :id => %r(\d+)
  #resources :checkpoint_fillings
  #resources :target_entities
  #resources :fillers
  #resources :free_text_fillings
  #resources :checkpoints
  #resources :free_texts
  #resources :sections
  #resources :section_types
  #resources :checklists
  #resources :checklist_types

  #match('check/responses/view_checklist_responses/:id').to(:controller => 'responses', :action => 'view_checklist_responses').name(:view_checklist_responses)
  #
  #match('check/checklists/fill_in_checklist/:id').to(:controller => 'checklists', :action => 'fill_in_checklist').name(:fill_in_checklist)
  #match('check/checklists/capture_checklist_data').to(:controller => 'checklists', :action => 'capture_checklist_data').name(:capture_checklist_data)
  #match('check/responses/view_response/:id/').to(:controller => 'responses', :action => 'view_response').name(:view_response)
  #match('check/responses/edit_response/:id/').to(:controller => 'responses', :action => 'edit_response').name(:edit_response)


#  ... 
end