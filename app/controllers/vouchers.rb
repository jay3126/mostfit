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
    sum = MoneyManager.get_money_instance("0")
    postings = []
    date_str = params["voucher"]["effective_on"]
    voucher_type = params["voucher_type"]
    effective_on = Date.parse(date_str)
    narration = params["voucher"]["narration"]
    credit_accounts = params['credit_accounts']
    credit_accounts.each do |credit_posting|
      ledger_id = credit_posting["account_id"].to_i
      money = MoneyManager.get_money_instance(credit_posting["amount"])
      sum = sum + money
      ledger = Ledger.get(ledger_id)
      credit_biz_location = CostCenter.get(credit_posting["cost_center_id"].to_i).biz_location
      credit_accounted_at = credit_biz_location.blank? ? nil : credit_biz_location.id
      postings << PostingInfo.new(money.amount, money.currency, :credit, ledger, credit_accounted_at)
    end
    debit_accounts = params['debit_accounts']
    debit_accounts.each do |debit_posting|
      ledger_id = debit_posting["account_id"].to_i
      money = MoneyManager.get_money_instance(debit_posting["amount"])
      sum = sum + money
      ledger = Ledger.get(ledger_id)
      debit_biz_location = CostCenter.get(debit_posting["cost_center_id"].to_i).biz_location
      debit_accounted_at = debit_biz_location.blank? ? nil : debit_biz_location.id
      postings << PostingInfo.new(money.amount, money.currency, :debit, ledger, debit_accounted_at)
    end
    accounting_facade = AccountingFacade.new(session.user)

    @voucher = accounting_facade.create_manual_voucher(sum, voucher_type, effective_on, postings, nil, nil, narration)
    if @voucher.save
      if params["form_submit"] == "Create and Continue"
        redirect url(:controller => "vouchers", :action => "new"), :message => {:notice => "Voucher was successfully created"}
      else
        ledger = @voucher.ledger_postings.first.ledger
        cost_center_id = params['credit_accounts'].first["cost_center_id"]
        redirect resource(ledger, :cost_center_id => cost_center_id), :message => {:notice => "Voucher was successfully created"}
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

  def tally_download
    if params[:from_date] and params[:to_date]
      search_options = {}
      location_ids   = []
      from_date      = Date.parse(params[:from_date])
      to_date        = Date.parse(params[:to_date])
      locations      = params[:biz_location_ids].blank? ? [] : params[:biz_location_ids]
      locations.each do |location_id|
        biz_location = BizLocation.get location_id
        location_ids = location_ids + LocationLink.all_children(biz_location).map(&:id)
      end
      file   = File.join("/", "tmp", "voucher_#{from_date.strftime('%Y-%m-%d')}_#{to_date.strftime('%Y-%m-%d')}_#{Time.now.to_i}.xml")
      search_options = {:effective_on.gte => from_date, :effective_on.lte => to_date}
      search_options.merge!(:accounted_at => locations.flatten.compact) unless locations.flatten.compact.blank?
      voucher_list = Voucher.get_voucher_list(search_options)
      Voucher.to_tally_xml(voucher_list, file)
      send_data(File.read(file), :filename => file)
    else
      render :layout => layout?
    end
  end

end # Vouchers
