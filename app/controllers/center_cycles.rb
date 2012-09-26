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
    both_dates = []
    unique_dates = []

    # GATE-KEEPING
    cgt_date_one_str = params[:cgt_date_one]
    cgt_date_one = Date.parse(cgt_date_one_str)

    cgt_date_two_str = params[:cgt_date_two]
    cgt_date_two = Date.parse(cgt_date_two_str)
    
    cgt_performed_by_staff = params[:cgt_performed_by_staff]
    branch_id = params[:parent_location_id]
    center_id = params[:child_location_id]
    @center_cycle = CenterCycle.first(:center_id => center_id, :cycle_number => 1)

    # VALIDATIONS

    unless @center_cycle.is_restarted
      # All three dates must be unique
      both_dates = [cgt_date_one_str, cgt_date_two_str]
      unique_dates = both_dates.uniq
      @errors << "Both CGT Date 1, CGT Date 2 must be different" unless both_dates.eql?(unique_dates)

      # greater than and less than validations on all three dates
      @errors << "CGT Date 2 must not be before CGT Date 1" if cgt_date_two < cgt_date_one
    end

    # Future date validations
    @errors << "CGT Date 1 must not be future date" if cgt_date_one > Date.today
    @errors << "CGT Date 2 must not be future date" if cgt_date_two > Date.today

    @errors << "CGT recorded by must not be blank" if cgt_performed_by_staff.blank?
    #OPERATIONS-PERFORMED
    if @errors.blank?
      begin
        @record_cgt = @center_cycle.update(:cgt_date_one => cgt_date_one, :cgt_date_two => cgt_date_two, :cgt_performed_by_staff => cgt_performed_by_staff, :cgt_recorded_at => DateTime.now())
        if @record_cgt
          message = {:notice => "CGT successfully completed"}
        else
          message = {:error => "#{@center_cycle.errors.first.to_s}"}
        end
      rescue => ex
        @errors << "An error has occurred: #{ex.message}"
      end
    else
      message = {:error => @errors.flatten.join(', ')}
    end
    redirect resource(:center_cycles, :mark_cgt_grt, :parent_location_id => branch_id, :child_location_id => center_id ), :message => message
  end

  def record_grt
    @errors = []
    # GATE-KEEPING
    grt_status = params[:grt_status]
    grt_completed_by_staff = params[:grt_completed_by_staff]
    grt_completed_on_str = params[:grt_completed_on]
    grt_completed_on = Date.parse(grt_completed_on_str)
    branch_id = params[:parent_location_id]
    center_id = params[:child_location_id]
    @center_cycle = CenterCycle.first(:center_id => center_id, :cycle_number => 1)

    # VALIDATIONS
    @errors << "GRT completed on date must not be future date" if grt_completed_on > Date.today
    @errors << "GRT recorded by must not be blank" if grt_completed_by_staff.blank?
    @errors << "Please select GRT status either pass or fail" if grt_status.blank?
    @errors << "GRT completed on date must be before CGT Date 2" if grt_completed_on < @center_cycle.cgt_date_two

    #OPERATIONS-PERFORMED
    if @errors.blank?
      begin
        @record_cgt = @center_cycle.update(:grt_status => grt_status, :grt_completed_by_staff => grt_completed_by_staff, :grt_completed_on => grt_completed_on, :grt_recorded_at => DateTime.now())
        if @record_cgt
          message = {:notice => "GRT successfully completed"}
        else
          message = {:error => "#{@center_cycle.errors.first.to_s}"}
        end
      rescue => ex
        @errors << "An error has occurred: #{ex.message}"
      end
    else
      message = {:error => @errors.flatten.join(', ')}
    end
    redirect resource(:center_cycles, :mark_cgt_grt, :parent_location_id => branch_id, :child_location_id => center_id ), :message => message
  end

  def restart_cgt
    # GATE-KEEPING
    center_cycle_id = params[:id]
    branch_id = params[:parent_location_id]
    center_id = params[:child_location_id]

    # INITIALIZATIONS
    @errors = []
    @center_cycle = CenterCycle.get center_cycle_id

    # OPERATIONS PERFORMED
    begin
      @center_cycle.update(
        :cgt_date_one => nil,
        :cgt_date_two => nil,
        :cgt_performed_by_staff => nil,
        :cgt_recorded_at => nil,
        :grt_status => Constants::CenterFormation::GRT_NOT_DONE,
        :grt_completed_by_staff => nil,
        :grt_completed_on => nil,
        :grt_recorded_at => nil,
        :is_restarted => true)
    rescue => ex
      @errors << "An error has occurred: #{ex.message}"
    end

    # RENDER/RE-DIRECT
    redirect resource(:center_cycles, :mark_cgt_grt, :parent_location_id => branch_id, :child_location_id => center_id)
  end

end