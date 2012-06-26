class CenterCycles < Application

  provides :xml, :yaml, :js, :html

  def create
    center = Center.get(params[:center_id])
    center_cycle = center.center_cycles.new(:initiated_on => params[:initiated_date], :created_by => session.user.id, :initiated_by_staff_id => center.manager.id, :created_at => Date.today)
    if center_cycle.save
      redirect resource(center.branch, center), :message => {:notice => "Save Successfully"}
    else
      redirect resource(center.branch, center), :message => {:error => center_cycle.errors.to_a.to_json}
    end
  end

  def update(id)
    center_cycle = CenterCycle.get params[:id]
    center = center_cycle.center
    unless params[:closed_date].blank?
      if Date.today >= Date.parse(params[:closed_date])
        center_cycle.update(:status => 'closed_center_cycle_status', :closed_on => params[:closed_date], :closed_by_staff_id => center.manager.id)
      else
        error = "INVALID DATE"
      end
    else
      c_number = center_cycle.cycle_number + 1
      center_cycle.update(:status => 'open_center_cycle_status', :closed_on => nil, :cycle_number => c_number, :closed_by_staff_id => nil, :initiated_on => params[:initiated_date])
    end
    
    if center_cycle.errors.blank? && error.blank?
      redirect resource(center.branch, center), :message => {:notice => "Save Successfully"}
    else
      redirect resource(center.branch, center), :message => {:error => center_cycle.errors.to_a.to_json}
    end
  end

  def mark_cgt_grt
    branch_id = params[:parent_location_id]
    center_id = params[:child_location_id]
    @branch = location_facade.get_location(branch_id) if branch_id
    @center = location_facade.get_location(center_id) if center_id
    @center_cycle_number = CenterCycle.get_current_center_cycle(@center.id)
    @cgt = CenterCycle.first(:center_id => @center.id, :cycle_number => 1)
    render
  end

  def record_cgt_grt
    @cgt = CenterCycle.first(:center_id => params[:child_location_id], :cycle_number => 1)
    is_saved = @cgt.update(:cgt_performed_by_staff => params[:cgt_performed_by_staff], :cgt_date_one => params[:cgt_date_one], :cgt_date_two => params[:cgt_date_two], :cgt_date_three => params[:cgt_date_three])
    if is_saved
      message = {:notice => "Save Successfully"}
    else
      message = {:error => "#{@cgt.errors.first.to_s}"}
    end
    redirect url("/mark_cgt_grt"), :message => message
  end
  
end # AccountBalances
