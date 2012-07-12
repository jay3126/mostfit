class UserLocations < Application

  def index
    @location_levels = LocationLevel.all
    display @location_levels
  end

  def show
    @biz_location = BizLocation.get params[:id]
    @date         = get_effective_date
    @eod_date     = params[:eod_date]
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
    @errors = []
    begin
      if @biz_location.location_level.level == 0
        @customers = ClientAdministration.get_clients_administered(@biz_location.id, get_effective_date)
      else
        @customers = ClientAdministration.get_clients_registered(@biz_location.id, get_effective_date)
      end
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
    @staff_postings = StaffPosting.get_staff_assigned(params[:id].to_i, get_effective_date)
    partial 'staffs_on_biz_location'
  end

  def location_eod_summary
    @biz_location_eod = {}
    @date = params[:eod_date].blank? ? get_effective_date : Date.parse(params[:eod_date])
    @biz_location = BizLocation.get params[:id]
    @eod_summary = @biz_location.location_eod_summary(@date)
    render :template => 'user_locations/location_eod_summary', :layout => layout?
  end

  def pdf_on_biz_location
    file     = ''
    @message = {}
    pdf_type = params[:pdf_type]
    biz_location = BizLocation.get params[:id]
    date         = params[:date].blank?? get_effective_date : params[:date]
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

  def record_seating_order
    list_of_clients = []
    @biz_location = BizLocation.get(params[:biz_location_id])
    client_sequence = params[:clients].split("&")
    if @biz_location.location_level.level == 0
      @clients = ClientAdministration.get_clients_administered(@biz_location.id, get_effective_date)
    else
      @clients = ClientAdministration.get_clients_registered(@biz_location.id, get_effective_date)
    end
    list_of_clients = @clients.each_with_index do |client,index|
      split_string = client_sequence[index].split("customer")[1]
      client_position = split_string.split("=")[1]
      #      SeatingOrder.assign_seating_order(list_of_clients, at_location_id)
    end
  end

end
