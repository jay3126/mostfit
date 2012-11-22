class UserLocations < Application

  def index
    @location_levels = LocationLevel.all
    display @location_levels
  end

  def show
    @biz_location = BizLocation.get params[:id]
    @date         = params[:date].blank? ? get_effective_date : Date.parse(params[:date])
    @parent_biz_location = LocationLink.get_parent(@biz_location, @date)
    level = @biz_location.location_level.level
    if level == 0
      @location_level = LocationLevel.first(:level => level)
      @biz_locations = @location_level.biz_locations
    else
      @location_level = LocationLevel.first(:level => level-1)
      @biz_locations = LocationLink.get_children_by_sql(@biz_location, @date)
      @meeting_dates = MeetingCalendar.all(:location_id => @biz_locations.map(&:id), :on_date => @date) if @location_level.has_meeting
    end
    display @biz_locations
  end

  def meeting_schedule
    @biz_location = BizLocation.get params[:id]
    raise NotFound unless @biz_location
    @meeting_schedule_infos = meeting_facade.get_meeting_schedules(@biz_location)
    partial "user_locations/meeting_schedule_list"
  end

  def meeting_calendar
    @biz_location = BizLocation.get params[:id]
    raise NotFound unless @biz_location
    @meeting_dates = meeting_facade.get_meeting_calendar(@biz_location, session[:effective_date] - Constants::Time::DEFAULT_PAST_MAX_DURATION_IN_DAYS )
    partial "user_locations/meeting_calendar"
  end

  def child_location_meetings_on_date
    @colName = ["location_id", '','',"meeting_time_begins_hours",'']
    @colCount = params[:iColumns]
    order = @colName[params[:iSortCol_0].to_i].blank? ? @colName.first : [@colName[params[:iSortCol_0].to_i]]
    @date = params[:date].blank? ? get_effective_date : Date.parse(params[:date])
    @parent_location = BizLocation.get(params[:id])
    @child_locations = LocationLink.get_children_by_sql(@parent_location, get_effective_date)
    @total_meetings = MeetingCalendar.all(:on_date => @date, :location_id => @child_locations.map(&:id)).count
    limit = params[:iDisplayLength].to_i <= 0 ? 10 : params[:iDisplayLength].to_i
    @meetings = MeetingCalendar.all(:order => order, :on_date => @date, :location_id => @child_locations.map(&:id), :limit => limit,:offset => params[:iDisplayStart].to_i, :conditions => [ ' location_id LIKE ? OR meeting_time_begins_hours LIKE ? OR meeting_time_begins_minutes LIKE ?', '%'+params[:sSearch]+'%','%'+params[:sSearch]+'%','%'+params[:sSearch]+'%'])
    @iTotalRecords = @total_meetings
    @iTotalDisplayRecords = params[:sSearch].blank? ? @iTotalRecords : @meetings.size
    @sEcho = params[:sEcho].to_i
    display @meetings, :layout => layout?
  end

  def weeksheet_collection
    @biz_location        = BizLocation.get params[:id]
    center_cycle_no      = CenterCycle.get_current_center_cycle params[:id]
    @center_cycle        = CenterCycle.get_cycle(params[:id], center_cycle_no)
    @parent_biz_location = LocationLink.get_parent(@biz_location, get_effective_date)
    @date                = params[:date].blank? ? session[:effective_date] : Date.parse(params[:date])
    @meeting_schedule    = meeting_facade.get_meeting_schedules(@biz_location)
    @user                = session.user
    @staff_member        = @user.staff_member
    unless @meeting_schedule.blank?
      @next_meeting      = meeting_facade.get_next_meeting(@biz_location, @date)
      @previous_meeting  = meeting_facade.get_previous_meeting(@biz_location, @date)
      @weeksheet         = collections_facade.get_collection_sheet(@biz_location.id, @date)
    end
    #generate scv route
    request    = Merb::Request.new(Merb::Const::REQUEST_PATH => url(:scv_checklist),Merb::Const::REQUEST_METHOD => "GET")
    @scv_route = Merb::Router.match(request)[1] rescue nil
    #generate ba route
    request   = Merb::Request.new(Merb::Const::REQUEST_PATH => url(:ba_checklist),Merb::Const::REQUEST_METHOD => "GET")
    @ba_route = Merb::Router.match(request)[1] rescue nil
    #generate  pa route
    request   = Merb::Request.new(Merb::Const::REQUEST_PATH => url(:pa_checklist),Merb::Const::REQUEST_METHOD => "GET")
    @pa_route = Merb::Router.match(request)[1] rescue nil
    #generate hc route
    request   = Merb::Request.new(Merb::Const::REQUEST_PATH => url(:hc_checklist),Merb::Const::REQUEST_METHOD => "GET")
    @hc_route = Merb::Router.match(request)[1] rescue nil

    display @weeksheet
  end

  def customers_on_biz_location
    @biz_location = BizLocation.get params[:id]
    @errors = []
    begin
      if @biz_location.location_level.level == 0
        @customers = ClientAdministration.get_clients_administered_by_sql(@biz_location.id, session[:effective_date])
      else
        @customers = ClientAdministration.get_clients_registered_by_sql(@biz_location.id, session[:effective_date])
      end
    rescue => ex
      @errors << ex.message
    end
    partial 'customers_on_biz_location'
  end


  def set_center_leader
    @biz_location = BizLocation.get params[:biz_location_id]
    # recent center leader
    center_leader_client = CenterLeaderClient.first(:biz_location_id => @biz_location.id, :date_assigned.lte => get_effective_date, :order => [:date_assigned.desc])
    unless center_leader_client.blank?
      client_id = center_leader_client.client_id
      @client = Client.get client_id
    end
    @errors = []
    begin
      if @biz_location.location_level.level == 0
        customers = ClientAdministration.get_clients_administered(@biz_location.id, get_effective_date)
      else
        customers = ClientAdministration.get_clients_registered(@biz_location.id, get_effective_date)
      end
      @customers = customers.collect{|c| c if client_facade.is_client_active?(c)}.compact
    rescue => ex
      @errors << ex.message
    end
    display @customers
  end

  def record_center_leader
    # INITIALIZATION
    @errors = []

    # GATE-KEEPING
    client_id = params[:client_id]
    at_location_id = params[:biz_location_id]
    on_effective_date = get_effective_date

    #VALIDATIONS
    @errors << "Select any client as center leader" if client_id.blank?

    # OPERATION PERFORMED
    if @errors.blank?
      begin
        CenterLeaderClient.set_center_leader(client_id, at_location_id, on_effective_date)
        message = {:notice => "Client ID: #{client_id} has set as Center Leader"}
      rescue => ex
        message = {:error => ex.message}
      end
    else
      message = {:error => @errors.to_a.flatten.join(', ')}
    end
    redirect url("user_locations/set_center_leader?biz_location_id=#{at_location_id}"), :message => message
  end

  def loans_on_biz_location
    @biz_location = BizLocation.get params[:id]
    if @biz_location.location_level.level == 0
      @lendings = LoanAdministration.get_loans_administered(@biz_location.id, session[:effective_date]).compact
    else
      @lendings = LoanAdministration.get_loans_accounted(@biz_location.id, session[:effective_date]).compact
    end
    partial 'loans_on_biz_location'
  end

  def biz_location_list
    @biz_location = BizLocation.get params[:id]
    @date = params[:meeting_day].blank? ? session[:effective_date] : Date.parse(params[:meeting_day])
    level = @biz_location.location_level.level
    if level == 0
      @location_level = LocationLevel.first(:level => level)
      @biz_locations = @location_level.biz_locations
    else
      @location_level = LocationLevel.first(:level => level-1)
      @biz_locations = LocationLink.get_children_by_sql(@biz_location, session[:effective_date])
      @meeting_dates = MeetingCalendar.all(:location_id => @biz_locations.map(&:id), :on_date => @date)
    end
    partial 'location_list', :layout => layout?
  end

  def child_location_list
    @colName = ["id" , "name", 'biz_location_address', 'creation_date']
    @colCount = params[:iColumns]
    order = @colName[params[:iSortCol_0].to_i].blank? ? @colName.first : [@colName[params[:iSortCol_0].to_i]]
    limit = params[:iDisplayLength].to_i <= 0 ? 10 : params[:iDisplayLength].to_i
    @parent_location = BizLocation.get(params[:id])
    @child_locations = LocationLink.get_children_by_sql(@parent_location, get_effective_date)
    @locations = BizLocation.all(:order => order, :id => @child_locations.map(&:id), :limit => limit,:offset => params[:iDisplayStart].to_i, :conditions => [ 'name LIKE ? OR biz_location_address LIKE ? OR creation_date LIKE ?', '%'+params[:sSearch]+'%','%'+params[:sSearch]+'%','%'+params[:sSearch]+'%'])
    @iTotalRecords = @child_locations.count
    @iTotalDisplayRecords = params[:sSearch].blank? ? @iTotalRecords : @locations.size
    @sEcho = params[:sEcho].to_i
    render :template => 'location_levels/fetch_locations', :layout => layout?
  end

  def child_locations
    @biz_location = BizLocation.get(params[:id])
    @location_level = @biz_location.location_level
    partial 'child_locations'
  end

  def staffs_on_biz_location
    @biz_location   = BizLocation.get params[:id]
    @staff_postings = StaffPosting.get_staff_assigned(params[:id].to_i, get_effective_date)
    partial 'staffs_on_biz_location'
  end

  def location_eod_summary
    @biz_location_eod = {}
    @date = params[:date].blank? ? get_effective_date : Date.parse(params[:date])
    @biz_location = BizLocation.get params[:id]
    @user = session.user
    @eod_summary = @biz_location.business_eod_on_date(@date)
    render :template => 'user_locations/location_eod_summary', :layout => layout?
  end

  def pdf_on_biz_location
    file     = ''
    @message = {}
    pdf_type = params[:pdf_type]
    biz_location = BizLocation.get params[:id]
    date         = params[:on_date].blank?? get_effective_date : params[:on_date]
    raise NotFound unless biz_location
    begin
      if pdf_type == 'disbursement_labels'
        file = biz_location.generate_disbursement_labels_pdf(session.user.id, date)
      elsif(pdf_type == 'disbursement_loans')
        file = biz_location.location_generate_disbursement_pdf(session.user.id, date)
      elsif(pdf_type == 'disbursement_loan_receipts')
        file = biz_location.generate_receipt_labels_pdf(session.user.id, date)
      elsif(pdf_type == 'loan_product_receipts')
        file = biz_location.location_loan_product_receipts_pdf(session.user.id, date)
      elsif(pdf_type == 'approved_loans')
        file = biz_location.generate_approve_loans_sheet_pdf(session.user.id, date)
      end
    rescue => ex
      @message = {:error => "An error has occured: #{ex.message}"}
    end
    
    if file.blank?
      redirect request.referer, :message => @message
    else
      send_data(file.to_s, :filename => "#{pdf_type}_#{biz_location.name}.pdf")
    end
  end


  def set_seating_order
    @biz_location = BizLocation.get(params[:biz_location_id])
    position = SeatingOrder.get_complete_seating_order(@biz_location.id)
    if position.blank?
      get_seating_order_data
    else
      @customers = []
      position.each do |p|
        @customers << Client.get(p)
      end
    end
    render
  end

  def record_seating_order
    client_ids = []
    @biz_location = BizLocation.get(params[:biz_location_id])
    client_sequence = params[:clients].split("&")
    get_seating_order_data
    @customers.each_with_index do |client,index|
      split_string = client_sequence[index].split("customer")[1]
      client_position = split_string.split("=")[1]
      client_ids << client_position.to_i
    end
    position = SeatingOrder.assign_seating_order(client_ids, @biz_location.id)
    @customers = []
    position.each do |p|
      @customers << Client.get(p)
    end
    render :set_seating_order
  end

  def location_scv
    @date            = params[:date].blank? ? get_effective_date : Date.parse(params[:date])
    @biz_location    = BizLocation.get params[:id]
    @child_locations = LocationLink.get_children_by_sql(@biz_location, @date)
    @scv             = VisitSchedule.all(:biz_location_id => @child_locations.map(&:id), :visit_scheduled_date => @date)
    render :template => 'user_locations/location_scv', :layout => layout?
  end

  def save_location_scv
    # INITIALIZATION
    @errors = []
    @message = {}

    # GATE-KEEPING
    at_location_id = params[:id]
    check_visit_ids = params[:was_visited]
    total_visit_ids = params[:visit_ids]

    #VALIDATIONS
    @errors << "Location cannot be blank" if at_location_id.blank?
    @errors << "Please select Was Visited checkbox" if check_visit_ids.blank?

    # OPERATION PERFORMED
    if @errors.blank?
      begin
        visit_schedules = total_visit_ids.collect{|c| VisitSchedule.get c}
        visit_schedules.each do |visit|
          v = check_visit_ids.include?(visit.id.to_s)
          visit.update(:was_visited => v)
        end
        @message = {:notice => "SCV update successfully"}
      rescue => ex
        @message = {:error => ex.message}
      end
    else
      @message = {:error => @errors.to_a.flatten.join(', ')}
    end

    #REDIRECT/RENDER
    redirect url(:controller => :user_locations, :action => :show, :id => at_location_id), :message => @message
  end

  def loan_applications_on_biz_location
    @biz_location = BizLocation.get params[:id]
    @all_loan_applications = loan_applications_facade.get_all_loan_applications_for_branch_and_center({:at_center_id => @biz_location.id})
    partial 'loan_applications/all_loan_applications'
  end
  
  def due_generation_for_location
    @locations = BizLocation.all('location_level.level' => 1)
    display @location
  end

  def get_due_generation_sheet_for_location
    @message = {}
    @date = params[:on_date]
    location_ids = params[:location_ids]
    @message[:error] = "Date cannot be blank" if @date.blank?
    if @message.blank?
      begin
        @date = Date.parse params[:on_date]
        @file = session.user.staff_member.generate_all_due_collection_pdf(session.user.id, location_ids, @date)
      rescue => ex
        @message = {:error => ex.message}
      end
    end
    if @message[:error].blank?
      send_data(File.read(@file), :filename => @file.split('/').last, :type => "application/zip")
    else
      redirect request.referer, :message => @message
    end
  end

  def zip_file_download
    file_url = params[:file_url]
    send_data(File.read(file_url), :filename => file_url.split('/').last, :type => "application/zip")
  end

  def branch_merge
    @first_location = @second_location = ''
    if !params[:first_location_id].blank? && !params[:second_location_id].blank?
      @first_location = BizLocation.get params[:first_location_id]
      @second_location = BizLocation.get params[:second_location_id]
      @on_date = Date.parse(params[:on_date])
    end
    display @first_location
  end

  def save_branch_merge
    # INITIALIZING VARIABLES USED THROUGHTOUT

    message = {:error => [], :notice => []}

    # GATE-KEEPING

    merged_location_id     = params[:merged_location_id]
    merge_into_location_id = params[:merge_into_location_id]
    effective_on           = params[:merge_date]
    performed_by_id        = params[:performed_by_id]
    recorded_by_id         = session.user.id

    # VALIDATIONS

    message[:error] << "Branch For Merge Location cannot be blank" if merged_location_id.blank?
    message[:error] << "Branch To Merge Location cannot be blank" if merge_into_location_id.blank?
    message[:error] << "Merge Date cannot blank" if effective_on.blank?
    message[:error] << "Please Select Performed By" if performed_by_id.blank?
    message[:error] << "Same Location cannot be merge" if merged_location_id == merge_into_location_id

    # OPERATIONS PERFORMEDmessage[:error] << "#{staff.to_s} created #{staff.creation_date} has a creation date later than #{b_creation_date}" if !b_managed_by.blank? && staff.creation_date > b_creation_date
    if message[:error].blank?
      begin
        merge_date          = Date.parse(effective_on)
        merged_location     = BizLocation.get merged_location_id
        merge_into_location = BizLocation.get merge_into_location_id
        loc_merge = LocationMerge.merge_to_location(merged_location, merge_into_location, merge_date, performed_by_id, recorded_by_id)
        if loc_merge.saved? && loc_merge.status == :completed
          message[:notice] << "Location Merged successfully"
        else
          LocationMerge.merge_roll_back_to_location(merged_location, merge_into_location, merge_date)
          message[:error] << loc_merge.errors.first
        end
      rescue => ex
        LocationMerge.merge_roll_back_to_location(merged_location, merge_into_location, merge_date)
        message[:error] << "An error has occured: #{ex.message}"
      end
    end

    #REDIRECT/RENDER
    message[:error].blank? ? message.delete(:error) : message.delete(:notice)
    redirect resource(:user_locations, :branch_merge, :first_location_id => merged_location_id, :second_location_id => merge_into_location_id, :on_date => effective_on), :message => message
  end


  private

  def get_seating_order_data
    if @biz_location.location_level.level == 0
      @customers_at_location = ClientAdministration.get_clients_administered(@biz_location.id, get_effective_date)
    else
      @customers_at_location = ClientAdministration.get_clients_registered(@biz_location.id, get_effective_date)
    end
    unless @customers_at_location.blank?
      @customers = []
      @customers_at_location.compact.each do |customer|
        has_outstanding = client_facade.client_has_outstanding_loan?(customer)
        is_active = client_facade.is_client_active?(customer)
        @customers << customer if has_outstanding && is_active
      end
    end
    @customers = @customers || @customers_at_location
  end

end
