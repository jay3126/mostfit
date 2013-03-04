class CenterCycles < Application
  
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

  def update
    is_eligible = []
    center_id = params[:id]
    current_center_cycle_number = params[:current_center_cycle_number]
    center_cycle = loan_applications_facade.get_center_cycle(center_id, current_center_cycle_number)
    center_cycle.cycle_number = current_center_cycle_number.to_i + 1
    loan_ids = LoanApplication.all(:at_center_id => center_id, :center_cycle_id => current_center_cycle_number).map{|la| la.lending_id}.compact
    loan_ids.each do |loan_id|
      loan = Lending.get loan_id
      status = loan.status
      if (status == LoanLifeCycle::STATUS_NOT_SPECIFIED || status == LoanLifeCycle::NEW_LOAN_STATUS ||
            status == LoanLifeCycle::APPROVED_LOAN_STATUS || status == LoanLifeCycle::DISBURSED_LOAN_STATUS)
        is_eligible << false
      end
    end
    if is_eligible.blank?
      center_cycle.save
      message = {:notice => "center cycle has been updated successfully"}
    else
      message = {:error => "center cycle cannot be updated there may be some active loans"}
    end
    redirect url("user_locations/weeksheet_collection/#{center_id}"), :message => message
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
      @center_cycle_number = loan_applications_facade.get_current_center_cycle_number(@center.id)
      @center_cycle = loan_applications_facade.get_current_center_cycle(@center.id)
      @loan_applications_status = LoanApplication.all(:fields => [:id, :client_name, :status], :at_branch_id => branch_id, :at_center_id => center_id, :center_cycle_id => @center_cycle.cycle_number)
    end

    render :mark_cgt_grt
  end

  def record_cgt
    @errors = []

    # GATE-KEEPING
    cgt_date_one_str = params[:cgt_date_one]
    cgt_date_one = Date.parse(cgt_date_one_str)

    cgt_date_two_str = params[:cgt_date_two]
    cgt_date_two = Date.parse(cgt_date_two_str)
    
    cgt_performed_by_staff = params[:cgt_performed_by_staff]
    branch_id = params[:parent_location_id]
    center_id = params[:child_location_id]
    @center_cycle = loan_applications_facade.get_current_center_cycle(center_id)
    @max_loan_authorization_date = LoanApplication.all(:at_branch_id => branch_id, :at_center_id => center_id).loan_authorizations.aggregate(:performed_on).max

    # VALIDATIONS
    # CGT date must not before loan application authorization date
    unless @max_loan_authorization_date.blank?
      @errors << "Both CGT Start Date and CGT End Date must be not before loan applciation authorization date (#{@max_loan_authorization_date.display})" if cgt_date_one < @max_loan_authorization_date || cgt_date_two < @max_loan_authorization_date
    end

    # greater than and less than validations on all three dates
    @errors << "CGT End Date must not be before CGT Start Date" if cgt_date_two < cgt_date_one

    # Future date validations
    @errors << "CGT Start Date must not be future date" if cgt_date_one > get_effective_date
    @errors << "CGT End Date must not be future date" if cgt_date_two > get_effective_date

    @errors << "CGT recorded by must not be blank" if cgt_performed_by_staff.blank?

    #OPERATIONS-PERFORMED
    if @errors.blank?
      begin
        @record_cgt = @center_cycle.update(:cgt_date_one => cgt_date_one, :cgt_date_two => cgt_date_two, :cgt_performed_by_staff => cgt_performed_by_staff, :cgt_recorded_at => get_effective_date)
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
    redirect resource(:center_cycles, :mark_cgt_grt, :parent_location_id => branch_id, :child_location_id => center_id, :center_cycle_id => @center_cycle.cycle_number), :message => message
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
    @center_cycle = loan_applications_facade.get_current_center_cycle(center_id)

    # VALIDATIONS
    @errors << "GRT completed on date must not be future date" if grt_completed_on > get_effective_date
    @errors << "GRT recorded by must not be blank" if grt_completed_by_staff.blank?
    @errors << "Please select GRT status either pass or fail" if grt_status.blank?
    @errors << "GRT completed on date must be before CGT End Date" if grt_completed_on < @center_cycle.cgt_date_two

    #OPERATIONS-PERFORMED
    if @errors.blank?
      begin
        @record_cgt = @center_cycle.update(:grt_status => grt_status, :grt_completed_by_staff => grt_completed_by_staff, :grt_completed_on => grt_completed_on, :grt_recorded_at => get_effective_date)
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
    redirect resource(:center_cycles, :mark_cgt_grt, :parent_location_id => branch_id, :child_location_id => center_id, :center_cycle_id => @center_cycle.cycle_number), :message => message
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
    redirect resource(:center_cycles, :mark_cgt_grt, :parent_location_id => branch_id, :child_location_id => center_id, :center_cycle_id => @center_cycle.cycle_number)
  end

  def get_date_difference
    begin
      start_date = Date.parse(params[:cgt_start_date])
      end_date = Date.parse(params[:cgt_end_date])
      days_passed = end_date.mjd - start_date.mjd
      return (days_passed < 0) ? "negative" : "#{days_passed}"
    rescue
      return("0")
    end
  end

end