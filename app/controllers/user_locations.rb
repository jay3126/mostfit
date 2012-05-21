class UserLocations < Application

  def index
    @location_levels = LocationLevel.all
    display @location_levels
  end

  def show
    @biz_location = BizLocation.get params[:id]
    level = @biz_location.location_level.level
    if level == 0
      @location_level = LocationLevel.first(:level => level)
      @biz_locations = @location_level.biz_locations
    else
      @location_level = LocationLevel.first(:level => level-1)
      @biz_locations = LocationLink.get_children(@biz_location, session[:effective_date])
    end
    display @biz_locations
  end

  def meeting_schedule
    @biz_location = BizLocation.get params[:id]
    raise NotFound unless @biz_location
    mf = FacadeFactory.instance.get_instance(FacadeFactory::MEETING_FACADE, session.user)
    @meeting_schedule_infos = mf.get_meeting_schedules(@biz_location)
    @meeting_schedule = MeetingSchedule.new
    display @meeting_schedule_infos
  end

  def meeting_calendar
    @biz_location = BizLocation.get params[:id]
    raise NotFound unless @biz_location
    mf = FacadeFactory.instance.get_instance(FacadeFactory::MEETING_FACADE, session.user)
    @meeting_dates = mf.get_meeting_calendar(@biz_location)
    partial "user_locations/meeting_calendar"
  end

  def weeksheet_collection
    @date = params[:date].blank? ? Date.today : Date.parse(params[:date])
    @biz_location = BizLocation.get params[:id]
    @weeksheet = CollectionsFacade.new(session.user.id).get_collection_sheet(@biz_location.id, @date)
    partial "centers/weeksheet"
  end

end