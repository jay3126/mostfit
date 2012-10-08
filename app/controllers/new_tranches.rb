class NewTranches < Application

  def list
    # GATE-KEEPING
    @errors = []
    funding_line_id = params[:id]
    @funding_line = NewFundingLine.get funding_line_id
    @funder = @funding_line.new_funder

    # OPERATIONS PERFORMED
    begin
      @tranches = @funding_line.new_tranches(:order => [ :created_at .asc ])
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
    @errors = []
    funding_line_id  = params[:new_funding_line_id]
    funder_id = params[:new_funder_id]
    assignment_type = params[:assignment_type]
    last_payment_date = params[:new_tranch][:last_payment_date]
    disbursal_date = params[:new_tranch][:disbursal_date]
    first_payment_date = params[:new_tranch][:first_payment_date]
    interest_rate = params[:interest_rate]
    amount_str = params[:amount]
    # OPERATIONS-PERFORMED
    if @errors.empty?
      @funding_line = NewFundingLine.get funding_line_id
      @funder = NewFunder.get funder_id
      @money = MoneyManager.get_money_instance(amount_str)
      amount = @money.amount
      currency = @money.currency
      @tranch = @funding_line.new_tranches.new({:amount => amount, :currency => currency, :interest_rate => interest_rate, :disbursal_date => disbursal_date,
          :first_payment_date => first_payment_date, :last_payment_date => last_payment_date, :assignment_type => assignment_type, :created_by => session.user.id})
      if @tranch.save
        message[:notice] = "Tranch created successfully"
        redirect("/new_tranches/list/#{funding_line_id}", :message => {:notice => "Tranch successfully created"})
      else
        message[:error] = @tranch.errors.first.to_s
        render :new
      end
    end
  end
  
end