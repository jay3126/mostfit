class CenterCycles < Application

  def new
    center =  Center.get(params[:center_id])
    center_cycle  = center.center_cycles.new(:closed_on => params[:date], :created_by => session.user.id,
                                             :initiated_by_staff_id => center.manager.id, :created_at => Date.today)
     if center_cycle.save
       message = "Save Succussfully"
     else
       message = "Can not save..."
     end
    redirect resource(center) ,:message => {:notice => message}
  end

  def update(id)
    center_cycle = CenterCycle.get params[:id]
    center_cycle.update(params[])
  end

end # AccountBalances
