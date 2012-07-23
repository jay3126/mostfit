class MeetingSchedules < Application

  def index
  end

  def new
    @biz_location     = BizLocation.get params[:biz_location_id]
    @meeting_schedule = MeetingSchedule.new
    render :template => 'meeting_schedules/new', :layout => layout?
  end

  def create

    # INITIALIZING VARIABLES USED THROUGHTOUT

    message = {}
    mf      = FacadeFactory.instance.get_instance(FacadeFactory::MEETING_FACADE, session.user)

    # GATE-KEEPING

    meeting_schedule            = params[:meeting_schedule][:meeting_frequency]
    meeting_begin_on            = Date.parse params[:meeting_schedule][:schedule_begins_on]
    meeting_time_begins_hours   = params[:meeting_schedule][:meeting_time_begins_hours].to_i
    meeting_time_begins_minutes = params[:meeting_schedule][:meeting_time_begins_minutes].to_i
    @biz_location               = BizLocation.get params[:biz_location_id]

    # VALIDATIONS

    message[:error] = "Please fill right value of time" unless Constants::Time::MEETING_HOURS_PERMISSIBLE_RANGE.include?(meeting_time_begins_hours) &&
      Constants::Time::MEETING_MINUTES_PERMISSIBLE_RANGE.include?(meeting_time_begins_minutes)
    message[:error] = "Bigin Date cannot be holiday" unless configuration_facade.permitted_business_days_in_month(meeting_begin_on).include?(meeting_begin_on)

    # OPERATIONS PERFORMED

    if message[:error].blank?
      begin
        msi = MeetingScheduleInfo.new(meeting_schedule, meeting_begin_on, meeting_time_begins_hours, meeting_time_begins_minutes)  
        if mf.setup_meeting_schedule @biz_location, msi
          message = {:notice => "Center Meeing Schedule successfully created"}
        else
          message = {:error => "Center Meeting Schedule creation fail"}
        end
      rescue => ex
        message = {:error => "An error has occured: #{ex.message}"}
      end
    end

    #REDIRECT/RENDER
    redirect request.referer, :message => message
  end

  def edit
  end

  def update
  end
end