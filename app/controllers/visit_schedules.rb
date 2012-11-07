class VisitSchedules < Application

  def index
    @scv = VisitSchedule.all
    render
  end

  def suggest_scv_for_branch
    message = {}
    biz_location = params[:biz_location_id]
    visit_scheduled_date = params[:visit_scheduled_date]

    # OPERATIONS
    begin
      @suggested_scv = VisitSchedule.schedule_visits(biz_location, visit_scheduled_date)
      message[:notice] = "Random suggestions generated"
    rescue => ex
      message[:error] = ex.message
    end
    redirect "/visit_schedules", :messgae => message
  end

end