class Vouchers < Application
  # provides :xml, :yaml, :js
  
  def index
    on_date_str = params[:on_date]
    @on_date = (on_date_str and !on_date_str.empty?) ? Date.parse(on_date_str) : nil

    cost_center_id_str = params[:cost_center_id]
    @cost_center_id = (cost_center_id_str and !cost_center_id_str.empty?) ? cost_center_id_str.to_i : nil

    @vouchers = @on_date ? Voucher.find_by_date_and_cost_center(@on_date, @cost_center_id) : []
    display @vouchers, :layout => layout?
  end

  def show(id)
    @voucher = Voucher.get(id)
    raise NotFound unless @voucher
    display @voucher
  end

  def new
    only_provides :html
    @voucher = Voucher.new
    display @voucher
  end

  def edit(id)
    only_provides :html
    @voucher = Voucher.get(id)
    raise NotFound unless @voucher
    display @voucher
  end

  def create(voucher)
    @voucher = Voucher.new(voucher)
    sum = 0
    postings = []
    date_str = params["voucher"]["effective_on"]
    effective_on = Date.parse(date_str)
    narration = params["voucher"]["narration"]
    credit_accounts = params['credit_accounts']
    credit_accounts.each do |credit_posting|
      ledger_id = credit_posting["account_id"].to_i
      amount = credit_posting["amount"].to_i
      sum += amount
      ledger = Ledger.get(ledger_id)
      postings << PostingInfo.new(amount, ledger.opening_balance_currency, :credit, ledger)
    end
    debit_accounts = params['debit_accounts']
    debit_accounts.each do |debit_posting|
      ledger_id = debit_posting["account_id"].to_i
      amount = debit_posting["amount"].to_i
      sum += amount
      ledger = Ledger.get(ledger_id)
      postings << PostingInfo.new(amount, ledger.opening_balance_currency, :debit, ledger)
    end
    currencies =  postings.map(&:currency).uniq!
    # raise ArgumentError, "Currencies Mismatch in Vouchers, #{currencies.to_json}" if (currencies.count > 1)
    money_sum = Money.new((sum * 100), currencies.first)
    accounting_facade = AccountingFacade.new(session.user)
    @voucher = accounting_facade.create_manual_voucher(money_sum, effective_on, postings, narration)
    if @voucher.save
      if params["form_submit"] == "Create and Continue"
        redirect url(:controller => "vouchers", :action => "new"), :message => {:notice => "Voucher was successfully created"}
      else
        redirect resource(@voucher), :message => {:notice => "Voucher was successfully created"}
      end
    else
      message[:error] = "Voucher failed to be created"
      render :new
    end
  end

  def update(id, voucher)
    @voucher = Voucher.get(id)
    raise NotFound unless @voucher
    if @voucher.update(voucher)
       redirect resource(@voucher)
    else
      display @voucher, :edit
    end
  end

  def destroy(id)
    @voucher = Voucher.get(id)
    raise NotFound unless @voucher
    if @voucher.destroy
      redirect resource(:vouchers)
    else
      raise InternalServerError
    end
  end

end # Vouchers
