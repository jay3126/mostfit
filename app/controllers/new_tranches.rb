class NewTranches < Application

  def show(id)
    @tranch = NewTranch.get(params[:id])
    raise NotFound unless @tranch
    @lendings = loan_assignment_facade.get_loans_assigned_to_tranch(@tranch)
    display @tranch
  end

  def list
    # GATE-KEEPING
    @errors = []
    funding_line_id = params[:id]
    @funding_line = NewFundingLine.get funding_line_id
    @funder = @funding_line.new_funder

    # OPERATIONS PERFORMED
    begin
      @tranches = @funding_line.new_tranches(:order => [:created_at.asc])
    rescue => ex
      @errors << ex.message
    end

    # RENDER/RE-DIRECT
    display [@tranches, @funding_line]
  end
  
  def new
    # GATE-KEEPING
    funding_line_id = params[:new_funding_line_id]
    @funding_line =  NewFundingLine.get funding_line_id
    @funder = @funding_line.new_funder

    # OPERATIONS PERFORMED
    begin
      @tranch = NewTranch.new
    rescue => ex
      @errors.push(ex.message)
    end
    
    # RENDER/RE-DIRECT
    display @tranch
  end
  
  def create
    # GATE-KEEPING
    funding_line_id     = params[:new_funding_line_id]
    funder_id           = params[:new_funder_id]
    amount_str          = params[:amount]
    interest_rate       = params[:interest_rate]
    first_payment_date  = params[:new_tranch][:first_payment_date]
    disbursal_date      = params[:new_tranch][:disbursal_date]
    last_payment_date   = params[:new_tranch][:last_payment_date].blank? ? nil : params[:new_tranch][:last_payment_date]
    assignment_type     = params[:assignment_type]

    # INITIALIZATIONS
    @errors = []
    @funding_line = NewFundingLine.get funding_line_id
    @funder = NewFunder.get funder_id
    
    # VALIDATIONS
    if amount_str.blank?
      @errors << "Amount must not be blank"
    else
      @money = MoneyManager.get_money_instance(amount_str)
      amount = @money.amount
      currency = @money.currency
      @errors << "Tranch amount must not be greater than funding line amount" if amount > @funding_line.amount
    end

    # OPERATIONS-PERFORMED
    if @errors.blank?
      @tranch = @funding_line.new_tranches.new({:amount => amount, :currency => currency, :interest_rate => interest_rate, :disbursal_date => disbursal_date,
          :first_payment_date => first_payment_date, :last_payment_date => last_payment_date, :assignment_type => assignment_type, :created_by => session.user.id})
      if @tranch.save!
        #used save! method to bypass an error which was disallowing it to save amounts in crores from front end but from backend it was working fine.
        #added a custom code for making entry in audit_trail table for tracking history.
        audit_params = {:auditable_id => @tranch.id, :auditable_type => "NewTranch", :action => :create,
            :changes => [{:created_by=>[nil, session.user.id]}, {:created_at=>[nil, @tranch.created_at]}, {:interest_rate=>[nil, interest_rate]},
                        {:assignment_type=>[nil, assignment_type]}, {:disbursal_date=>[nil, disbursal_date]}, {:first_payment_date=>[nil, first_payment_date]},
                        {:last_payment_date=>[nil, last_payment_date]}, {:currency=>[nil, currency]}, {:amount=>[nil, amount]}],
            :created_at => DateTime.now, :user_role => session.user.staff_member.designation.role_class, :user_id => session.user.id, :type => :log}
        @audit_trail = AuditTrail.new(audit_params)
        @audit_trail.save
        message[:notice] = "Tranch created successfully"
        redirect("/new_tranches/list/#{funding_line_id}", :message => {:notice => "Tranch successfully created"})
      else
        render :new
      end
    else
      @tranch = @funding_line.new_tranches.new({:amount => amount, :currency => currency, :interest_rate => interest_rate, :disbursal_date => disbursal_date,
          :first_payment_date => first_payment_date, :last_payment_date => last_payment_date, :assignment_type => assignment_type, :created_by => session.user.id})
      message[:error] = @errors.flatten.join(', ')
      render :new
    end
  end
  
  def edit
    @tranch = NewTranch.get(params[:id])
    @funding_line = @tranch.new_funding_line
    @funder = @funding_line.new_funder
    display @tranch
  end
  
  def update
    # GATE-KEEPING
    tranch_id = params[:id]
    funding_line_id  = params[:new_funding_line_id]
    funder_id = params[:new_funder_id]
    assignment_type = params[:new_tranch][:assignment_type]
    last_payment_date = params[:new_tranch][:last_payment_date]
    disbursal_date = params[:new_tranch][:disbursal_date]
    first_payment_date = params[:new_tranch][:first_payment_date]
    interest_rate = params[:new_tranch][:interest_rate]
    amount_str = params[:new_tranch][:amount]

    # INITIALIZATION
    @errors = []
    @tranch = NewTranch.get tranch_id
    @funding_line = NewFundingLine.get funding_line_id
    @funder = NewFunder.get funder_id

    # VALIDATIONS
    if amount_str.blank?
      @errors << "Amount must not be blank"
    else
      @money = MoneyManager.get_money_instance(amount_str)
      amount = @money.amount
      currency = @money.currency
      @errors << "Tranch amount must not be greater than funding line amount" if amount > @funding_line.amount
    end
    
    #remembering the old values.
    old_amount = @tranch.amount
    old_interest_rate = @tranch.interest_rate
    old_disbursal_date = @tranch.disbursal_date
    old_first_payment_date = @tranch.first_payment_date
    old_last_payment_date = @tranch.last_payment_date
    old_assignment_type = @tranch.assignment_type
    
    # OPERATIONS PERFORMED
    if @errors.blank?
      begin
        values = {:amount => amount, :currency => currency, :interest_rate => interest_rate, :disbursal_date => disbursal_date,
            :first_payment_date => first_payment_date, :last_payment_date => last_payment_date, :assignment_type => assignment_type, :created_by => session.user.id}
        @tranch.attributes = values
        @tranch.save!
        #a very dirty patch. needs to be refactored.
        if (old_amount != amount)
          audit_params = {:auditable_id => @tranch.id, :auditable_type => "NewTranch", :action => :update,
              :changes => [{:amount=>[old_amount, amount]}], :created_at => DateTime.now, :user_role => session.user.staff_member.designation.role_class, 
              :user_id => session.user.id, :type => :log}
          
        elsif (old_interest_rate != interest_rate)
          audit_params = {:auditable_id => @tranch.id, :auditable_type => "NewTranch", :action => :update,
              :changes => [{:interest_rate=>[old_interest_rate, interest_rate]}], :created_at => DateTime.now,
              :user_role => session.user.staff_member.designation.role_class, :user_id => session.user.id, :type => :log}
          
        elsif (old_disbursal_date != disbursal_date)
          audit_params = {:auditable_id => @tranch.id, :auditable_type => "NewTranch", :action => :update,
              :changes => [{:disbursal_date=>[old_disbursal_date, disbursal_date]}], :created_at => DateTime.now,
              :user_role => session.user.staff_member.designation.role_class, :user_id => session.user.id, :type => :log}
            
        elsif (old_first_payment_date != first_payment_date)
          audit_params = {:auditable_id => @tranch.id, :auditable_type => "NewTranch", :action => :update,
              :changes => [{:first_payment_date=>[old_first_payment_date, first_payment_date]}], :created_at => DateTime.now,
              :user_role => session.user.staff_member.designation.role_class, :user_id => session.user.id, :type => :log}
            
        elsif (old_last_payment_date != last_payment_date)
          audit_params = {:auditable_id => @tranch.id, :auditable_type => "NewTranch", :action => :update,
              :changes => [{:last_payment_date=>[old_last_payment_date, last_payment_date]}], :created_at => DateTime.now,
              :user_role => session.user.staff_member.designation.role_class, :user_id => session.user.id, :type => :log}
            
        elsif (old_assignment_type != assignment_type)
          audit_params = {:auditable_id => @tranch.id, :auditable_type => "NewTranch", :action => :update,
              :changes => [{:assignment_type=>[old_assignment_type, assignment_type]}], :created_at => DateTime.now,
              :user_role => session.user.staff_member.designation.role_class, :user_id => session.user.id, :type => :log}
            
          
        end
        @audit_trail = AuditTrail.new(audit_params)
        @audit_trail.save
      rescue => ex
        @errors << ex.message
      end
    end
    if @errors.blank?
      redirect("/new_tranches/list/#{funding_line_id}", :message => {:notice => "Tranch successfully updated"})
    else
      message[:error] = @errors.flatten.join(', ')
      render :edit
    end
  end

end
