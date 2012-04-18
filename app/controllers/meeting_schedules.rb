class MeetingSchedules < Application

  def index
    @center = Center.get params[:center_id]
    mf = MeetingFacade.new session.user
    @meeting_schedule_infos = mf.get_meeting_schedules(@center)
    display @meeting_schedules
  end

  def new
    @center = Center.get params[:center_id]
    mf = MeetingFacade.new session.user
    @meeting_schedule_infos = mf.get_meeting_schedules(@center)
    @meeting_schedule = MeetingSchedule.new
    display @meeting_schedule
  end

  def create
    @center = Center.get params[:center_id]
    if Constants::Time::MEETING_HOURS_PERMISSIBLE_RANGE.include?(params[:meeting_schedule][:meeting_time_begins_hours]) && Constants::Time::MEETING_MINUTES_PERMISSIBLE_RANGE.include?(params[:meeting_schedule][:meeting_time_begins_minutes])
      message = {:error => "Please fill vaild value of Meeting Time."}
    else
      msi = MeetingScheduleInfo.new(params[:meeting_schedule][:meeting_frequency],params[:meeting_schedule][:schedule_begins_on],params[:meeting_schedule][:meeting_time_begins_hours],params[:meeting_schedule][:meeting_time_begins_minutes])
      mf = MeetingFacade.new session.user
      mf.setup_meeting_schedule @center, msi
      if mf.setup_meeting_schedule @center, msi
        message = {:notice => "Add Meeting Schedule Successfully"}
      else
        message = {:error => "Cannot Add Meeting Schedule Successfully"}
      end
    end
    redirect resource(:meeting_schedules, :center_id => @center.id), :message => message
  end

  def edit
    @center = Center.get params[:center_id]
    @meeting_schedule = MeetingSchedule.get params[:id]
    display @meeting_schedule
  end

  def update
    @center = Center.get params[:center_id]
    @meeting_schedule = MeetingSchedule.get params[:id]
    if @meeting_schedule.update(params[:meeting_schedule])
      message = {:notice => "Add Meeting Schedule Successfully"}
      redirect resource(:meeting_schedules, :center_id => @center.id), :message => message
    else
      message = {:error => "Cannot Add Meeting Schedule Successfully"}
      render :edit
    end
  end
end