class Portfolios < Application
  # provides :xml, :yaml, :js
  before :get_context
  include DateParser
  layout :determine_layout

  def index
    @portfolios = Portfolio.all
    redirect resource(@funder) if @funder
    display @portfolios
  end

  def show(id)
    @portfolio = Portfolio.get(id)
    raise NotFound unless @portfolio
    display @portfolio
  end

  def new
    @portfolio = Portfolio.new
    @counter = params[:counter]||1
    if request.xhr?
      @model = Kernel.const_get(params[:model].camelcase)
      if params[:more]=="chain"
        @model = @model.relationships.find_all{|key, prop| prop.class==DataMapper::Associations::OneToMany::Relationship}.map{|x| x[0].singularize}
      elsif params[:model]
        @properties = get_properties_for(@model)
      end
      partial :form
    elsif request.method==:get
      render :advanced, :layout => layout?
    end
  end

  def create(portfolio)
    debugger
    # if the final Loan chain is not provided in params, we have to add some stuff to params
    max                               = params[:model].keys.map(&:to_i).max
    unless params[:model][max.to_s]   == "loan"
      params[:model][(max+1).to_s]    = "loan"
      params[:property][(max+1).to_s] = "id"
      params[:value][(max+1).to_s]    = {"id" => "0"}
      params[:operator][(max+1).to_s] = "gt"
      params[:more][(max+1).to_s]     = ""
    end

    @search  = Search.new(params)
    @objects = @search.process
    @portfolio = Portfolio.new(portfolio)
    @portfolio.created_by_user_id = session.user.id
    @added_on = Date.parse(params[:added_on])
    if @portfolio.save
      @securitised_loans =  @portfolio.is_securitised ? Portfolio.all(:is_securitised => true).portfolio_loans.aggregate(:loan_id) : []
      @objects.each do |o|
        next if @securitised_loans.include?(o.id)
        pl = PortfolioLoan.new(:loan => o, :portfolio => @portfolio, :added_on => @added_on)
        pl.save
      end
      redirect resource(:portfolios), :message => {:notice => 'Portfolio was succesfully created'}
      else
      render :advanced
    end
  end

  def edit(id)
    only_provides :html
    @portfolio = Portfolio.get(id)
    raise NotFound unless @portfolio
    disallow_updation_of_verified_portfolios
    @portfolio.added_on  = Date.parse(params[:added_on])  if params[:added_on] and not params[:added_on].blank?
    @portfolio.branch_id = params[:branch_id] if params[:branch_id] and not params[:branch_id].blank?
    @portfolio.disbursed_after = Date.parse(params[:disbursed_after]) if params[:disbursed_after] and not params[:disbursed_after].blank?
    @data      = @portfolio.eligible_loans
    @centers   = Center.all(:id => LoanHistory.ancestors_of_portfolio(@portfolio, Center))
    display @portfolio
  end


  def update(id, portfolio)
    @portfolio = Portfolio.get(id)
    raise NotFound unless @portfolio
    @portfolio.attributes = portfolio
    if @portfolio.save_self
       redirect resource(@funder)
    else
      @data = @portfolio.eligible_loans
      display @portfolio, :edit
    end
  end

  def destroy(id)
    @portfolio = Portfolio.get(id)
    raise NotFound unless @portfolio
    if @portfolio.destroy
      redirect resource(:portfolios)
    else
      raise InternalServerError
    end
  end

  def cashflow(id)
    # returns the cashflow for a given potfolio between specified dates
    # returns raw json
    debugger
    @portfolio = Portfolio.get(id)
    raise NotFound unless @portfolio
    @portfolio.cashflow(params)
  end
    

  # def loans
  #   @portfolio = params[:id] ? Portfolio.get(params[:id]) : Portfolio.new
  #   @loans     = @portfolio.eligible_loans(params[:center_id])
  #   render :layout => layout?
  # end

  private
  def get_context
    if params[:funder_id] and not params[:funder_id].blank?
      @funder = Funder.get(params[:funder_id])
      raise NotFound unless @funder
    end
  end
  def disallow_updation_of_verified_portfolios
    raise NotChangeable if @portfolio.verified_by_user_id
  end
end # Portfolios
