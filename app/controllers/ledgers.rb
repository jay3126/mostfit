class Ledgers < Application
  # provides :xml, :yaml, :js

  def index
    @accounts_chart = params[:accounts_chart_id].blank? ? accounting_facade.get_primary_chart_of_accounts : AccountsChart.get(params[:accounts_chart_id])
    @ledgers        = @accounts_chart.blank? ? [] : @accounts_chart.ledgers
    display @ledgers, :layout => layout?
  end

  def show(id)
    @accounting_facade = AccountingFacade.new(session.user)
    @ledger = @accounting_facade.get_ledger(id)
    raise NotFound unless @ledger
    @date = Date.today
    @date = Date.parse(params[:date]) unless params[:date].blank?
    @cost_center_id = params[:cost_center_id]
    @vouchers = @ledger.get_vouchers(@date, @cost_center_id)
    display @ledger
  end

  def new
    only_provides :html
    @ledger = Ledger.new
    display @ledger
  end

  def edit(id)
    only_provides :html
    @ledger = Ledger.get(id)
    raise NotFound unless @ledger
    display @ledger
  end

  def create(ledger)
    @ledger = Ledger.save_ledger(ledger[:name], ledger[:account_type], ledger[:open_on], ledger[:opening_balance_amount], ledger[:opening_balance_effect])
    if @ledger.save
      redirect resource(@ledger), :message => {:notice => "Ledger '#{@ledger.name}' was successfully created"}
    else
      message[:error] = "Ledger failed to be created"
      render :new
    end
  end

  def update(id, ledger)
    @ledger = Ledger.get(id)
    raise NotFound unless @ledger
    if @ledger.update(ledger)
      redirect resource(@ledger)
    else
      display @ledger, :edit
    end
  end

  def destroy(id)
    @ledger = Ledger.get(id)
    raise NotFound unless @ledger
    if @ledger.destroy
      redirect resource(:ledgers)
    else
      raise InternalServerError
    end
  end

end # Ledgers
