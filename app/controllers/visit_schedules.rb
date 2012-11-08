class VisitSchedules < Application

  def index
    @scv_suggestions = VisitSchedule.all
    render
  end

  def suggest_scv_for_branch
    message = {}
    area_id = params[:area_id]
    branch_id = params[:branch_id]
    visit_scheduled_date = params[:visit_scheduled_date]

    begin
      @suggested_scv = VisitSchedule.schedule_visits(branch_id, visit_scheduled_date)
      if @suggested_scv.blank?
        message[:error] = "Suggestions cannot be generated"
      else
        message[:notice] = "Random suggestions generated"
      end
    rescue => ex
      message[:error] = ex.message
    end
    redirect resource(:visit_schedules, :area_id => area_id, :branch_id => branch_id, :visit_scheduled_date => visit_scheduled_date), :message => message
  end

end