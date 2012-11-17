Merb.logger.info("Compiling routes...")
Merb::Router.prepare do

  resources :asset_categories do
    resources :asset_sub_categories do
      resources :asset_types
    end
  end

  resources :new_funders do
    resources :new_funding_lines do
      resources :new_tranches
    end
  end
  
  resources :loan_assignments, :id => %r(\d+)
  resources :psl_sub_categories
  resources :priority_sector_lists
  resources :visit_schedules, :id => %r(\d+)

  #book-keeping from bk begins
  resources :home, :collection => {:effective_date => [:get]}
  resources :ledgers
  resources :bank_account_ledgers
  resources :accounting_rules
  resources :book_keepings, :collection => {:eod_process => [:get], :bod_process => [:get], :perform_eod_process => [:get,:post], :perform_bod_process => [:get,:post]}
  resources :vouchers, :id => %r(\d+)
  resources :cost_centers
  resources :transaction_summaries
  resources :loan_files,               :id => %r(\d+)
  resources :loan_applications,        :id => %r(\d+), :collection => {:suspected_duplicates => [:get], :bulk_create => [:post], :bulk_create_loan_applicant => [:post], :bulk_new => [:post], :loan_application_list => [:get], :duplicate_record => [:get]}
  resources :overlap_report_responses, :id => %r(\d+)
  resources :overlap_report_requests, :id => %r(\d+)
  resources :center_cycles, :id => %r(\d+), :collection => {:mark_cgt_grt => [:post]}
  resources :user_locations, :id => %r(\d+), :member => {:child_location_meetings_on_date => [:get], :weeksheet_collection => [:get]}, :collection => {:save_branch_merge => [:get, :post], :branch_merge => [:get], :get_due_generation_sheet_for_location => [:get], :due_generation_for_location => [:get], :zip_file_download=>[:get]}

  #book-keeping from bk ends

  resources :auth_override_reasons
  resources :branch_eod_summaries
  resources :cheque_books, :id => %r(\d+)
  resources :securitizations, :id => %r(\d+)
  resources :encumberances
  resources :third_parties
  resources :staff_member_attendances
  resources :staff_postings
  resources :simple_fee_products
  resources :simple_insurance_products

  resources :banks do
    resources :bank_branches do
      resources :bank_accounts
    end
  end
  resources :money_deposits, :id => %r(\d+), :collection => {:bulk_record_varification => [:get,:post],:get_money_deposits => [:get], :get_bank_branches => [:get], :get_bank_accounts => [:get], :mark_verification => [:get]}
  resources :holiday_calendars
  resources :location_holidays, :id => %r(\d+), :collection => {:edit_custom_calendar => [:get], :update_custom_calendar => [:get, :post], :download_custom_calendar_format => [:get], :record_custom_calendar => [:get, :post], :custom_calendar => [:get], :holiday_for_location => [:get], :create_holiday_for_location => [:put]}

  resources :api_accesses
  resources :monthly_targets
  resources :account_balances
  resources :bookmarks
  resources :branch_diaries
  resources :stock_registers
  resources :asset_registers
  resources :locations, :id => %r(\d+)
  resources :insurance_products
  resources :accounting_periods
  resources :journals, :id => %r(\d+)
  resources :loan_utilizations
  resources :account_types
  resources :meeting_schedules
  resources :accounts, :id => %r(\d+) do
    resources :accounting_periods do
      resources :account_balances
    end
  end
  resources :reasons
  resources :location_levels, :id => %r(\d+), :collection => {:fetch_locations => [:get]}
  resources :biz_locations, :id => %r(\d+), :collection => {:location_checklists => [:get], :map_locations => [:get]}, :member => {:update_biz_location => [:put], :biz_location_clients => [:get], :centers_for_selector => [:get], :biz_location_form => [:get], :loan_products => [:get]}
  resources :new_clients, :collection => {:update_client_location => [:get,:put], :update_client_telephone_number => [:get,:put], :create_client_for_selected_loan_application => [:get, :put], :create_clients_for_loan_file => [:get], :death_claim_insurance => [:get, :put], :record_death_event => [:put, :get], :record_death_claim_insurance => [:get, :put], :all_deceased_clients => [:get, :put]}, :member => {:register_death_event => [:get]}
  resources :simple_insurance_policies
  resources :payment_transactions, :id => %r(\d+), :collection => {:create_group_payments => [:get], :weeksheet_payments => [:get], :payment_form_for_lending => [:get], :payment_by_staff_member => [:get], :payment_by_staff_member_for_location => [:get]}
  resources :designations
  resources :user_roles
  resources :fee_instances, :collection => {:fee_instance_on_lending => [:get]}
  resources :rules, :id => %r(\d+)
  resources :bookmarks
  resources :audit_items
  resources :attendances
  resources :client_types
  resources :document_types
  resources :comments        
  resources :documents
  resources :audit_trails
  resources :insurance_policies
  resources :insurance_companies
  resources :occupations
  resources :loan_purposes
  resources :lending_products
  resources :lendings, :id => %r(\d+), :member => {:reschedule_loan_installment => [:get], :save_reschedule_loan_installment => [:get,:put], :record_lending_preclose => [:put]}, :collection => {:approve_write_off_lendings => [:put,:get], :bulk_lending_preclose => [:get], :record_bulk_lending_preclose => [:put], :write_off_lendings => [:get]}
  resources :staff_attendances
  resources :holidays
  resources :verifications
  resources :ledger_entries
  resources :users, :id => %r(\d+)
  resources :staff_members, :id => %r(\d+) do
    resources :staff_member_attendances
  end
  resources :clients, :id => %r(\d+) do
    resources :insurance_policies
    resources :attendances
    resources :claims
  end
  resources :client_groups do
    resources :grts
    resources :cgts
  end
  resources :payments
  resources :repayment_styles

  resources :uploads, :member => {:continue => [:get], :reset => [:get], :show_csv => [:get], :reload => [:get], :extract => [:get], :stop => [:get]}

  # maintainer slice
  slice(:maintainer, :path_prefix => "maintain")
  add_slice(:checklister_slice,:path_prefix=>"check")

  slice(:merb_auth_slice_password, :name_prefix => nil, :path_prefix => "")
  match('/search(/:action)').to(:controller => 'searches')
  match('/searches(/:action)').to(:controller => 'searches')
  match('/reports/graphs').to(:controller => 'reports', :action => 'graphs')
  match('/reports/show(/:id)').to(:controller => 'reports', :action => 'show')
  match('/reports/:report_type(/:id)').to(:controller => 'reports', :action => 'show').name(:show_report)
  resources :reports

  namespace :credit_bureaus do 
    match('/:name/:action').to(:controller => :name)
  end

  match('/client_verifications(/:action)').to(:controller => 'client_verifications').name(:client_verifications)
  match('/admin(/:action)').to(:controller => 'admin').name(:admin)
  match('/admin(/:action/:id)').to(:controller => 'admin').name(:admin)
  match('/dashboard(/:action)').to(:controller => 'dashboard').name(:dashboard)
  match('/change_password').to(:controller => "users", :action => 'change_password').name(:change_password)
  match('/preferred_locale').to(:controller => "users", :action => 'preferred_locale').name(:preferred_locale)
  match('/graph_data/:action(/:id)').to(:controller => 'graph_data').name(:graph_data)
  match('/entrance(/:action)').to(:controller => 'entrance').name(:entrance)
  match('/staff_members/:id/day_sheet').to(:controller => 'staff_members', :action => 'day_sheet').name(:day_sheet)
  match('/staff_members/:id/day_sheet.:format').to(:controller => 'staff_members', :action => 'day_sheet', :format => ":format").name(:day_sheet_with_format)
  match('/staff_members/:id/disbursement_sheet').to(:controller => 'staff_members', :action => 'disbursement_sheet').name(:disbursement_sheet)
  match('/staff_members/:id/disbursement_sheet.:format').to(:controller => 'staff_members', :action => 'disbursement_sheet', :format => ":format").name(:disbursement_sheet_with_format)
  match('/browse(/:action)(.:format)').to(:controller => 'browse').name(:browse)
  match('/home(/:action)(.:format)').to(:controller => 'home').name(:home)
  match('/client/:action').to(:controller => 'clients').name(:client_actions)
  # this uses the redirect_to_show methods on the controllers to redirect some models to their appropriate urls
  match('/documents/:action(/:id)').to(:controller => "documents").name(:documents_action_link)
  match('/:controller/:id', :id => %r(\d+)).to(:action => 'redirect_to_show').name(:quick_link)
  match('/rules/get').to(:controller => 'rules', :action => 'get')
  match('/securitizations/:action').to(:controller => 'securitizations').name(:securitization_actions)
  match('/securitizations/upload_data/:id').to(:controller => 'securitizations', :action => "upload_data")
  match('/securitizations/save_data').to(:controller => 'securitizations', :action => "save_data")
  match('/encumberances/:action').to(:controller => 'encumberances').name(:encumberance_actions)
  match('/encumberances/upload_data/:id').to(:controller => 'encumberances', :action => "upload_data")
  match('/third_parties/:action').to(:controller => 'third_parties').name(:third_party_actions)
  match('/third_parties/new').to(:controller => 'third_parties', :action => 'new')
  match('/third_parties/:id').to(:controller => 'third_parties', :action => 'show')
  match('/auth_override_reasons/:action').to(:controller => 'auth_override_reasons').name(:auth_override_reason_actions)
  match('/auth_override_reasons/new').to(:controller => 'auth_override_reasons', :action => 'new')

  #API Route
  match('/api/v1') do
    match('/browse.:format').to(:controller => 'browse', :action => 'index')
    match('/users/:id.:format').to(:controller => 'users', :action => 'show')
    match('/staff_members.:format').to(:controller => 'staff_members', :action =>'index')
    match('/staff_members/:id.:format').to(:controller => 'staff_members', :action =>'show')
    match('/transaction_logs.:format').to(:controller => 'transaction_logs', :action =>'index')
    match('/transaction_logs/:id.:format').to(:controller => 'transaction_logs', :action =>'show')
    match('/model_event_logs.:format').to(:controller => 'model_event_logs', :action =>'index')
    match('/model_event_logs/:id.:format').to(:controller => 'model_event_logs', :action =>'show')
    match('/client_groups.:format', :method => "get").to(:controller => 'client_groups', :action =>'index')
    match('/client_groups/:id.:format').to(:controller => 'client_groups', :action =>'show')
    match('/users.:format').to(:controller => 'users', :action =>'index')
    match('/attendance.:format', :method => "post").to(:controller => 'attendances', :action =>'create')
    match('/client_groups.:format', :method => "post").to(:controller => 'client_groups', :action =>'create')
    match('/holidays.:format', :method => "get").to(:controller => 'holidays', :action =>'index')
    match('/handshake.:format', :method => "get").to(:controller => 'entrance', :action =>'handshake')
    match('/errors.:format', :method => "get").to(:controller => 'exceptions', :action =>'index')
    match('/securitizations.:format', :method => "post").to(:controller => 'securitizations', :action => 'create')
    match('/third_parties.:format', :method => "post").to(:controller => 'third_parties', :action => 'create')
  end
  match('/accounts/:account_id/accounting_periods/:accounting_period_id/account_balances/:id/verify').to(:controller => 'account_balances', :action => 'verify').name(:verify_account_balance)
  match('/accounting_periods/:id/close').to(:controller => 'accounting_periods', :action => 'close').name(:close_accounting_period)
  match("/accounting_periods/:id/period_balances").to(:controller => "accounting_periods", :action => "period_balances").name(:period_balances)


  resources :checklister
  match("/checklister/surprise_center_visit_checklist").to(:controller => "checklister", :action => "surprise_center_visit_checklist").name(:scv_checklist)
  match("/checklister/business_audit_checklist").to(:controller => "checklister", :action => "business_audit_checklist").name(:ba_checklist)
  match("/checklister/process_audit_checklist").to(:controller => "checklister", :action => "process_audit_checklist").name(:pa_checklist)
  match("/checklister/customer_audit_checklist").to(:controller => "checklister", :action => "customer_audit_checklist").name(:cc_checklist)
  match("/checklister/healthcheck_checklist").to(:controller => "checklister", :action => "healthcheck_checklist").name(:hc_checklist)
  default_routes
  match('/').to(:controller => 'entrance', :action =>'root')
end
