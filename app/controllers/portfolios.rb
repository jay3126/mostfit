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
    @portfolio_loans = @portfolio.portfolio_loans(:order => [:loan_id]).paginate(:per_page => 50, :page => params[:page] || 1)
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
    @portfolio.params = params
    @added_on = Date.parse(params[:added_on])
    Portfolio.transaction do |t|
      if @portfolio.save
        @securitised_loans =  @portfolio.is_securitised ? Portfolio.all(:is_securitised => true).portfolio_loans.aggregate(:loan_id) : []
        # some portfilios can be really big, so we go the bulk route
        # of course, does not write in the audit trail....
        # TODO write this in the audit trail
        interesting_loan_ids = (@objects[:loan] - @securitised_loans)
        dropped_loans = @objects[:loan] - interesting_loan_ids
        pls = interesting_loan_ids.map do |loan_id|
          {:loan_id => loan_id, :portfolio_id => @portfolio.id, :added_on => @added_on}
        end.compact
        sql = get_bulk_insert_sql("portfolio_loans", pls)
        if repository.adapter.execute(sql)
          redirect resource(:portfolios), :message => {:notice => "Portfolio was succesfully created. #{dropped_loans.count} conflicting loans ignored"}
        else
          render :advanced
        end
      else
        render :advanced
      end
    end
  end 

  def edit(id)
    only_provides :html
    @portfolio = Portfolio.get(id)
    raise NotFound unless @portfolio
    disallow_updation_of_verified_portfolios
    display @portfolio
  end


  def update(id, portfolio)
    @portfolio = Portfolio.get(id)
    raise NotFound unless @portfolio
    if params[:submit].downcase == "remove selected loans"
      PortfolioLoan.all(:id => params[:loan].keys.map(&:to_i)).destroy # these are ids for the portfolio_loan, not the loan
      redirect request.referer, :message => {:success => "Loans removed from portfolio"}
    elsif params[:delete_ids] # got some delete ids in a text box
      ids = params[:delete_ids].split(",").map(&:to_i)
      if @portfolio.portfolio_loans(:loan_id => ids).destroy
        redirect resource(@portfolio), :message => {:success => "Succesfully removed #{ids.count} loans"}
      else
        raise
      end
    elsif params[:add_ids] # got some delete ids in a text box
      @added_on = Date.parse(params[:added_on])
      ids = params[:add_ids].split(",").map(&:to_i)
      @securitised_loans =  @portfolio.is_securitised ? Portfolio.all(:is_securitised => true).portfolio_loans.aggregate(:loan_id) : []
      interesting_loan_ids = (ids - @securitised_loans)
      dropped_loans = ids - interesting_loan_ids
      pls = ids.map do |loan_id|
        {:loan_id => loan_id, :portfolio_id => @portfolio.id, :added_on => @added_on}
      end.compact
      sql = get_bulk_insert_sql("portfolio_loans", pls)
      if repository.adapter.execute(sql)
        redirect resource(@portfolio), :message => {:notice => "#{ids.count} loans added to portfolio. #{dropped_loans.count} conflicting loans ignored"}
      else
        redirect resource(@portfolio, :edit), :message => {:error => "Ooops! Something went wrong"}
      end
    else
      # new loans keep getting added all the time to the database and many of them will match the search criteria
      # so, we give the option to add such loans to the portfolio
      # use the original parameters to conduct another search
      @search  = Search.new(@portfolio.params)
      @objects = @search.process
      @added_on = Date.parse(params[:added_on])
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
    @portfolio = Portfolio.get(id)
    raise NotFound unless @portfolio
    @portfolio.cashflow(params)
  end

  def securitise(id)
    # this updates all the loans in portfolio and sets their loan_pool_id to the portfolio id
    # securitised portfolios can now get their own high class reporting like everyone else ;-)
    # the problem is with the audit trail, we need to do everything by hand
    # because portfolios can be HUUUGGGE and going loan by loan is not really an option
    debugger
    @portfolio = Portfolio.get(id)
    raise NotFound unless @portfolio
    redirect request.referer, :message => {:notice => "This portfolio not securitisable"} unless  @portfolio.is_securitisable
    redirect request.referer, :message => {:notice => "This portfolio is already securitised"} if @portfolio.is_securitised
    loan_ids = @portfolio.loans.aggregate(:id)
    t0 = DateTime.now
    Portfolio.transaction do |t|
      audit_trails = loan_ids.map{|x| 
        {:auditable_id => x, :auditable_type => "Loan", :action => 2,
          :changes => {:loan_pool_id => [0,id]}.to_yaml, :created_at => t0,
          :type => 1, :user_id => session.user.id}
      }
      repository.adapter.execute("update loans set loan_pool_id = #{id} where id in (#{loan_ids.join(',')})")
      sql = get_bulk_insert_sql("audit_trail", audit_trails)
      repository.adapter.execute(sql)
      @portfolio.is_securitised = true
      @portfolio.save
      redirect request.referer, :message => {:success => "Loans have been marked as securitsed"}
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
