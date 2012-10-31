class Securitizations < Application

  require "tempfile"

  def index
    @securitizations=Securitization.all
    display @securitizations
  end
  
  def show
    @securitization = Securitization.get(params[:id])
    raise NotFound unless @securitization
    @date = params[:secu_date].blank? ? get_effective_date : Date.parse(params[:secu_date])
    @lendings = loan_assignment_facade.get_loans_assigned(@securitization,@date) 

    do_calculations

    render :template => 'securitizations/show', :layout => layout?
  end

  def new
    @securitization=Securitization.new
    display @securitization
  end
  
  def create(securitization)
    @securitization = Securitization.new(securitization)
    @errors = []
    @errors << "Securitization name must not be blank " if params[:securitization][:name].blank?
    @errors << "Effective date must not be blank " if params[:securitization][:effective_on].blank?
    if @errors.blank?
      if(Securitization.all(:name => @securitization.name).count==0)
        if @securitization.save!
          redirect("/securitizations", :message => {:notice => "Securitization '#{@securitization.name}' (Id:#{@securitization.id}) successfully created"})
        else
          message[:error] = "Securitization failed to be created"
          render :new  # error messages will show
        end
      else
        message[:error] = "Securitization with same name already exists !"
        render :new  # error messages will show
      end
    else
      message[:error] = @errors.to_s
      render :new
    end
  end

  def loans_for_securitization_on_date
    @securitization = Securitization.get(params[:id])
    raise NotFound unless @securitization
    @date = params[:secu_date].blank? ? get_effective_date : Date.parse(params[:secu_date])
    @lendings = loan_assignment_facade.get_loans_assigned(@securitization,@date) 

    do_calculations

    render :template => 'securitizations/show', :layout => layout?
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
    rescue => ex
      @errors << ex.message
    end
  end

end