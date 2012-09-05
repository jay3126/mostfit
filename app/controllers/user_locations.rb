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
      @biz_locations = LocationLink.get_children(@biz_location, @date)
      @meeting_dates = meeting_facade.get_meetings_for_loncations_on_date(@biz_locations, @date) if @location_level.has_meeting
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

  def weeksheet_collection
    @biz_location = BizLocation.get params[:id]
    center_cycle_no = CenterCycle.get_current_center_cycle params[:id]
    @center_cycle =  CenterCycle.get_cycle(params[:id], center_cycle_no)
    @parent_biz_location = LocationLink.get_parent(@biz_location, get_effective_date)
    set_effective_date(Date.today) if session[:effective_date].blank?
    @date = params[:date].blank? ? session[:effective_date] : Date.parse(params[:date])
    @meeting_schedule = meeting_facade.get_meeting_schedules(@biz_location)
    unless @meeting_schedule.blank?
      @next_meeting = meeting_facade.get_next_meeting(@biz_location, @date)
      @previous_meeting = meeting_facade.get_previous_meeting(@biz_location, @date)
      @weeksheet = collections_facade.get_collection_sheet(@biz_location.id, @date)
    end
    #generate scv route
    request = Merb::Request.new(Merb::Const::REQUEST_PATH => url(:scv_checklist),Merb::Const::REQUEST_METHOD => "GET")
    @scv_route = Merb::Router.match(request)[1] rescue nil
    #generate ba route
    request = Merb::Request.new(Merb::Const::REQUEST_PATH => url(:ba_checklist),Merb::Const::REQUEST_METHOD => "GET")
    @ba_route = Merb::Router.match(request)[1] rescue nil
    #generate  pa route
    request = Merb::Request.new(Merb::Const::REQUEST_PATH => url(:pa_checklist),Merb::Const::REQUEST_METHOD => "GET")
    @pa_route = Merb::Router.match(request)[1] rescue nil
    #generate hc route
    request = Merb::Request.new(Merb::Const::REQUEST_PATH => url(:hc_checklist),Merb::Const::REQUEST_METHOD => "GET")
    @hc_route = Merb::Router.match(request)[1] rescue nil



    display @weeksheet
  end

  def customers_on_biz_location
    @biz_location = BizLocation.get params[:id]
    @errors = []
    begin
      if @biz_location.location_level.level == 0
        @customers = ClientAdministration.get_clients_administered(@biz_location.id, session[:effective_date])
      else
        @customers = ClientAdministration.get_clients_registered(@biz_location.id, session[:effective_date])
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
      @customers = customers.collect{|c| c if client_facade.has_death_event?(c) == false}.compact
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
      @biz_locations = LocationLink.get_children(@biz_location, session[:effective_date])
      @meeting_dates = meeting_facade.get_meetings_for_loncations_on_date(@biz_locations, @date)
    end
    partial 'location_list', :layout => layout?
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
    @eod_summary = @biz_location.location_eod_summary(@user, @date)
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
      end
    rescue => ex
      @message = {:error => "An error has occured: #{ex.message}"}
    end
    
    if file.blank?
      redirect request.referer, :message => @message
    else
      send_data(file.to_s, :filename => "disbursement_labels_#{biz_location.name}.pdf")
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
    @child_locations = LocationLink.get_children(@biz_location, @date)
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
        has_outstanding = customer.client_has_outstanding_loan?(customer)
        no_death_event = client_facade.has_death_event?(customer) == false
        @customers << customer if has_outstanding && no_death_event
      end
    end
    @customers = @customers || @customers_at_location
  end

end
