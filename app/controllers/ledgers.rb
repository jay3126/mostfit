class Ledgers < Application
  # provides :xml, :yaml, :js

  def index
    @ledgers = Ledger.all
    display @ledgers, :layout => layout?
  end

  def show(id)
    @accounting_facade = AccountingFacade.new(session.user)
    @ledger = @accounting_facade.get_ledger(id)
    raise NotFound unless @ledger
    @date = Date.today
    @date = Date.parse(params[:date]) unless params[:date].blank?
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
    @ledger = Ledger.new(ledger)
    if @ledger.save
      redirect resource(:ledgers), :message => {:notice => "Ledger '#{@ledger.name}' was successfully created"}
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
