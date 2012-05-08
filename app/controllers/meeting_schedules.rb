class MeetingSchedules < Application

  def index
  end

  def new
  end

  def create

    # INITIALIZING VARIABLES USED THROUGHTOUT

    message = {}
    mf = FacadeFactory.instance.get_instance(FacadeFactory::MEETING_FACADE, session.user)

    # GATE-KEEPING

    meeting_schedule = params[:meeting_schedule][:meeting_frequency]
    meeting_begin_on = Date.parse params[:meeting_schedule][:schedule_begins_on]
    meeting_time_begins_hours = params[:meeting_schedule][:meeting_time_begins_hours].to_i
    meeting_time_begins_minutes = params[:meeting_schedule][:meeting_time_begins_minutes].to_i
    @center = Center.get params[:center_id]

    # VALIDATIONS

    message[:error] = "Please fill right value of time" unless Constants::Time::MEETING_HOURS_PERMISSIBLE_RANGE.include?(meeting_time_begins_hours) &&
      Constants::Time::MEETING_MINUTES_PERMISSIBLE_RANGE.include?(meeting_time_begins_minutes)

    # OPERATIONS PERFORMED

    if message[:error].blank?
      begin
        msi = MeetingScheduleInfo.new(meeting_schedule, meeting_begin_on, meeting_time_begins_hours, meeting_time_begins_minutes)  
        if mf.setup_meeting_schedule @center, msi
          message = {:notice => "Center Meeing Schedule successfully created"}
        else
          message = {:error => "Center Meeting Schedule creation fail"}
        end
      rescue => ex
        message = {:error => "An error has occured: #{ex.message}"}
      end
    end

    #REDIRECT/RENDER
    redirect resource(@center), :message => message
  end

  def edit
  end

  def update
  end
end