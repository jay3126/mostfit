class CenterCycles < Application

  provides :xml, :yaml, :js, :html
  
  def create
    center =  Center.get(params[:center_id])
    center_cycle  = center.center_cycles.new(:initiated_on => params[:initiated_date], :created_by => session.user.id,
      :initiated_by_staff_id => center.manager.id, :created_at => Date.today, :cycle_number => 1,
      :status => 'open_center_cycle_status')
    if center_cycle.save
      redirect resource(center.branch, center) ,:message => {:notice => "Save Succussfully"}
    else
      redirect resource(center.branch, center) ,:message => {:error => "Can not save..."}
    end
  end

  def update(id)
    center_cycle = CenterCycle.get params[:id]
    center = center_cycle.center
    c_number = center_cycle.cycle_number + 1
    unless params[:closed_date].blank?
      if Date.today >= Date.parse(params[:closed_date])
        center_cycle.update(:status => 'closed_center_cycle_status', :closed_on => params[:closed_date], :cycle_number => c_number, :closed_by_staff_id => center.manager.id)
      else
        error = "invild date"
      end
    else
      center_cycle.update(:status => 'open_center_cycle_status', :closed_on => nil, :cycle_number => c_number, :closed_by_staff_id => nil, :initiated_on => params[:initiated_date])
    end
    
    if center_cycle.errors.blank? && error.blank?
      redirect resource(center.branch, center), :message => {:notice => "Save Succussfully"}
    else
      redirect resource(center.branch, center), :message => {:error => "Can not update.."}
    end
  end

end # AccountBalances
