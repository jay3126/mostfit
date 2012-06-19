class UserLocations < Application

  def index
    @location_levels = LocationLevel.all
    display @location_levels
  end

  def show
    @biz_location = BizLocation.get params[:id]
    @date         = get_effective_date
    @parent_biz_location = LocationLink.get_parent(@biz_location, @date)
    level = @biz_location.location_level.level
    if level == 0
      @location_level = LocationLevel.first(:level => level)
      @biz_locations = @location_level.biz_locations
    else
      @location_level = LocationLevel.first(:level => level-1)
      @biz_locations = LocationLink.get_children(@biz_location, @date)
      mf = FacadeFactory.instance.get_instance(FacadeFactory::MEETING_FACADE, session.user)
      @meeting_dates = mf.get_meetings_for_loncations_on_date(@biz_locations, @date) if @location_level.has_meeting
    end
    display @biz_locations
  end

  def meeting_schedule
    @biz_location = BizLocation.get params[:id]
    raise NotFound unless @biz_location
    mf = FacadeFactory.instance.get_instance(FacadeFactory::MEETING_FACADE, session.user)
    @meeting_schedule_infos = mf.get_meeting_schedules(@biz_location)
    @meeting_schedule = MeetingSchedule.new
    partial "user_locations/meeting_schedule_list"
  end

  def meeting_calendar
    @biz_location = BizLocation.get params[:id]
    raise NotFound unless @biz_location
    mf = FacadeFactory.instance.get_instance(FacadeFactory::MEETING_FACADE, session.user)
    @meeting_dates = mf.get_meeting_calendar(@biz_location, session[:effective_date] - Constants::Time::DEFAULT_PAST_MAX_DURATION_IN_DAYS )
    partial "user_locations/meeting_calendar"
  end

  def weeksheet_collection
    @biz_location = BizLocation.get params[:id]
    @parent_biz_location = LocationLink.get_parent(@biz_location, get_effective_date)
    set_effective_date(Date.today) if session[:effective_date].blank?
    @date = params[:date].blank? ? session[:effective_date] : Date.parse(params[:date])
    mf = FacadeFactory.instance.get_instance(FacadeFactory::MEETING_FACADE, session.user)
    @meeting_schedule = mf.get_meeting_schedules(@biz_location)
    unless @meeting_schedule.blank?
      @next_meeting = mf.get_next_meeting(@biz_location, @date)
      @previous_meeting = mf.get_previous_meeting(@biz_location, @date)
      @weeksheet = CollectionsFacade.new(session.user.id).get_collection_sheet(@biz_location.id, @date)
    end
    display @weeksheet
  end

  def customers_on_biz_location
    @biz_location = BizLocation.get params[:id]
    if @biz_location.location_level.level == 0
      @customers = ClientAdministration.get_clients_administered(@biz_location.id, session[:effective_date])
    else
      @customers = ClientAdministration.get_clients_registered(@biz_location.id, session[:effective_date])
    end
    partial 'customers_on_biz_location'
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
      mf = FacadeFactory.instance.get_instance(FacadeFactory::MEETING_FACADE, session.user)
      @meeting_dates = mf.get_meetings_for_loncations_on_date(@biz_locations, @date)
    end
    partial 'location_list', :layout => layout?
  end

  def staffs_on_biz_location
    @biz_location = BizLocation.get params[:id]
    @staffs = LocationManagement.get_staffs_on_location(@biz_location, get_effective_date)
    partial 'staffs_on_biz_location'
  end

  def location_eod_summary
    @biz_location_eod = {}
    @biz_location = BizLocation.get params[:id]
    rf = FacadeFactory.instance.get_instance(FacadeFactory::REPORTING_FACADE, get_effective_date)
    @biz_location_eod[:total_loans_disbursed] = rf.loans_scheduled_for_disbursement_by_branches_on_date(@biz_location.id, get_effective_date)
    partial 'location_eod_summary'
  end
end