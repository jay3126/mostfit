class NewTranches < Application

  def show(id)
    @tranch = NewTranch.get(params[:id])
    raise NotFound unless @tranch
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
      if @tranch.save
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
    
    # OPERATIONS PERFORMED
    if @errors.blank?
      begin
        @tranch.update_attributes({:amount => amount, :currency => currency, :interest_rate => interest_rate, :disbursal_date => disbursal_date,
            :first_payment_date => first_payment_date, :last_payment_date => last_payment_date, :assignment_type => assignment_type, :created_by => session.user.id})
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
