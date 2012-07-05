class CenterCycles < Application

  provides :xml, :yaml, :js, :html
  
  def create
    center_id = params[:center_id]
    center = BizLocation.get(center_id)
    center_cycle = CenterCycle.new(:initiated_on => params[:initiated_date], :created_by => session.user.id,
      :initiated_by_staff_id => session.user.id, :created_at => Date.today, :center_id => center_id)
    if center_cycle.save
      message = {:notice => "Center cycle successfully created for center: #{center.name}"}
    else
      message = {:error => center_cycle.errors.flatten.join(', ')}
    end
    redirect url(:controller => :user_locations, :action => :weeksheet_collection, :id => center_id), :message => message
  end

  def mark_cgt_grt
    @errors = []
    branch_id = params[:parent_location_id]
    center_id = params[:child_location_id]
    @branch = location_facade.get_location(branch_id) if branch_id
    @center = location_facade.get_location(center_id) if center_id

    # VALIDATION
    unless params[:flag] == 'true'
      @errors << "No branch was selected" if @branch.blank?
      @errors << "No center was selected" if @center.blank?
    end
    unless @center.blank?
      @center_cycle_number = CenterCycle.get_current_center_cycle(@center.id)
      @center_cycle = CenterCycle.first(:center_id => @center.id, :cycle_number => 1)
    end
    
    render :mark_cgt_grt
  end

  def record_cgt
    @errors = []
    # GATE-KEEPING
    cgt_date_one = params[:cgt_date_one]
    cgt_date_two = params[:cgt_date_two]
    cgt_date_three = params[:cgt_date_three]
    cgt_performed_by_staff = params[:cgt_performed_by_staff]
    branch_id = params[:parent_location_id]
    center_id = params[:child_location_id]
    
    # VALIDATIONS
    @errors << "CGT recorded by must not be blank" if cgt_performed_by_staff.blank?
    
    #OPERATIONS-PERFORMED
    if @errors.blank?
      begin
        @center_cycle = CenterCycle.first(:center_id => center_id, :cycle_number => 1)
        @record_cgt = @center_cycle.update(:cgt_date_one => cgt_date_one, :cgt_date_two => cgt_date_two, :cgt_date_three => cgt_date_three, :cgt_performed_by_staff => cgt_performed_by_staff, :cgt_recorded_at => DateTime.now())
        if @record_cgt
          message = {:notice => "Save Successfully"}
        else
          message = {:error => "#{@center_cycle.errors.first.to_s}"}
        end
      rescue => ex
        @errors << "An error has occurred: #{ex.message}"
      end
    end
    redirect resource(:center_cycles, :mark_cgt_grt, :parent_location_id => branch_id, :child_location_id => center_id ), :message => message
  end

  def record_grt
    @errors = []
    # GATE-KEEPING
    grt_status = params[:grt_status]
    grt_completed_by_staff = params[:grt_completed_by_staff]
    grt_completed_on = params[:grt_completed_on]
    branch_id = params[:parent_location_id]
    center_id = params[:child_location_id]

    # VALIDATIONS
    @errors << "CGT recorded by must not be blank" if grt_completed_by_staff.blank?

    #OPERATIONS-PERFORMED
    if @errors.blank?
      begin
        @center_cycle = CenterCycle.first(:center_id => center_id, :cycle_number => 1)
        @record_cgt = @center_cycle.update(:grt_status => grt_status, :grt_completed_by_staff => grt_completed_by_staff, :grt_completed_on => grt_completed_on, :grt_recorded_at => DateTime.now())
        if @record_cgt
          message = {:notice => "Save Successfully"}
        else
          message = {:error => "#{@center_cycle.errors.first.to_s}"}
        end
      rescue => ex
        @errors << "An error has occurred: #{ex.message}"
      end
    end
    redirect resource(:center_cycles, :mark_cgt_grt, :parent_location_id => branch_id, :child_location_id => center_id ), :message => message
  end
  
end # AccountBalances
