class Encumberances < Application
  # provides :xml, :yaml, :js

  def index
    @encumberances = Encumberance.all
    display @encumberances
  end

  def new
    only_provides :html
    @encumberance = Encumberance.new
    display @encumberance
  end

  def edit(id)
    only_provides :html
    @encumberance = Encumberance.get(id)
    raise NotFound unless @encumberance
    display @encumberance
  end

  def create(encumberance)
    # INITIALIZING VARIABLES USED THROUGHTOUT
    @errors = []
    facade = FacadeFactory.instance.get_instance(FacadeFactory::LOAN_ASSIGNMENT_FACADE, User.first)
    @encumberance = Encumberance.new(encumberance)

    # GATE-KEEPING
    name = params[:encumberance][:name]
    amount = params[:encumberance][:assigned_value]
    effective_on = params[:encumberance][:effective_on]

    # VALIDATIONS
    @errors << "Name cannot be blank" if name.blank?
    @errors << "Amount cannot be blank" if amount.blank?
    @errors << "Date of commencement cannot be blank" if effective_on.blank?

    # OPERATIONS
    if @errors.blank?
      begin
        @money = MoneyManager.get_money_instance(amount)
        encum = facade.create_encumberance(name, effective_on, @money)
        redirect resource(:encumberances), :message => {:notice => "Encumbrance was successfully created"}
      rescue => ex
        message[:error] = ex.message
        render :new
      end
    else
      message[:error] = @errors.flatten.join(', ')
      render :new
    end
  end

  def update(id, encumberance)
    @encumberance = Encumberance.get(id)
    raise NotFound unless @encumberance
    if @encumberance.update(encumberance)
      redirect resource(@encumberance)
    else
      display @encumberance, :edit
    end
  end

  def destroy(id)
    @encumberance = Encumberance.get(id)
    raise NotFound unless @encumberance
    if @encumberance.destroy
      redirect resource(:encumberances)
    else
      raise InternalServerError
    end
  end

  def upload_data(id)
    @id=id
    @encumberance=Encumberance.get(id)
    @upload = Upload.new
    display @upload
  end

  def loans_for_encumberance_on_date
    @encumberance = Encumberance.get(params[:id])
    raise NotFound unless @encumberance
    @date = params[:encu_date].blank? ? get_effective_date : Date.parse(params[:encu_date])
    @lendings = loan_assignment_facade.get_loans_assigned(@encumberance,@date)
    
    #calculate various things to show about the encumberance    
    do_calculations

    render :template => 'encumberances/show', :layout => layout?
  end

  def do_calculations
    @errors = []
    money_hash_list = []

    begin 
      @lendings.each do |lending| 
        lds = LoanDueStatus.most_recent_status_record_on_date(lending, @date)
        money_hash_list << lds.to_money
      end 
        
      in_currency = MoneyManager.get_default_currency
      @total_money = Money.add_money_hash_values(in_currency, *money_hash_list)
      if @total_money[:actual_total_outstanding] < @encumberance.to_money[:assigned_value]
        @shortfall_or_excess = "Shortfall"
      else
        @shortfall_or_excess = "Excess"
      end
         
      @difference = Money.net_amount(@total_money[:actual_total_outstanding], @encumberance.to_money[:assigned_value])
    rescue => ex
      @errors << ex.message
    end
  end


end