class Tranches < Application
  provides :xml, :yaml, :js
  include DateParser

  def list(id)

    # GATE-KEEPING
    funding_line_id=id
    
    # VALIDATION
    if FundingLine.get(funding_line_id).nil?
      redirect("/funders", :message => {:notice => "Funding line not found"})
    end
    # OPERATIONS PERFORMED
    
    begin
      @funding_line=FundingLine.get(id)
      @tranches=@funding_line.tranches(:order => [ :date_of_commencement .asc ])
      #@tranches.sort! { |a,b| a.date_of_commencement <=> b.date_of_commencement }
    rescue => ex
      #@errors.push(ex.message)
    end

    # POPULATING RESPONSE AND OTHER VARIABLES
    
    # RENDER/RE-DIRECT
    display [@tranches,@funding_line]
  end	

  def index
    render @tranches	
  end
  
  def new(id)
    # GATE-KEEPING
    funding_line_id=id
    
    # VALIDATION
    if FundingLine.get(funding_line_id).nil?
      redirect(params[:return], :message => {:notice => "Funding line not found"})
    end
    # OPERATIONS PERFORMED
    
    begin
      @tranch=Tranch.new
      @tranch.funding_line_id=id
    rescue => ex
      @errors.push(ex.message)
    end

    # POPULATING RESPONSE AND OTHER VARIABLES
    
    # RENDER/RE-DIRECT
    display @tranch
  end
  
  def create(tranch)
    # GATE-KEEPING
    @errors = []
    @tranch = Tranch.new(tranch)
    @errors << "Tranch name must not be blank " if params[:tranch][:name].blank?
    @errors << "Date must not be blank " if params[:tranch][:date_of_commencement].blank?
    if @errors.empty?
      # VALIDATION
      if(Tranch.all(:name => @tranch.name,:funding_line=>@tranch.funding_line).count!=0)
        message[:error] = "Tranch with same name already exists !"
        render :new  # error messages will show
      else
        # OPERATIONS PERFORMED
        if @tranch.save
          redirect("/tranches/list/#{@tranch.funding_line_id}", :message => {:notice => "Tranch '#{@tranch.name}' (Id:#{@tranch.id}) successfully created"})
        else
          message[:error] = "Tranch failed to be created"
          render :new  # error messages will show
        end
      end
    else
      message[:error] = @errors.flatten.join(', ')
      render :new  # error messages will show
    end
  end

  def show
    #GATEKEEPING
    @errors = []
    debugger

    @tranch = Tranch.get(params[:id])
    raise NotFound unless @tranch
    @date = params[:tranch_date].blank? ? get_effective_date : Date.parse(params[:tranch_date])
    @lendings = loan_assignment_facade.get_loans_assigned_to_tranch(@tranch, @date)
      
    do_calculations

    render :template => 'tranches/show', :layout => layout?
  end

  def do_calculations
    money_hash_list = []
    @lendings.each do |lending|
      lds = LoanDueStatus.most_recent_status_record_on_date(lending, @date)
      money_hash_list << lds.to_money
    end 
    
    in_currency = MoneyManager.get_default_currency
    @total_money = Money.add_money_hash_values(in_currency, *money_hash_list)
  end

end
