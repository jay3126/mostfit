class ExpenseVouchers < Application
  # provides :xml, :yaml, :js

  def index
    @expense_vouchers = Journal.all.paginate(:per_page => 20, :page => params[:page] ||1 )
    display @expense_vouchers
  end

  def show(id)
    @expense_voucher = ExpenseVoucher.get(id)
    raise NotFound unless @expense_voucher
    display @expense_voucher
  end

  def new
    only_provides :html
    @expense_voucher = ExpenseVoucher.new
    display @expense_voucher, :layout => layout?
  end

  def edit(id)
    only_provides :html
    @expense_voucher = ExpenseVoucher.get(id)
    raise NotFound unless @expense_voucher
    display @expense_voucher
  end

  def create(expense_voucher)
    @expense_voucher = ExpenseVoucher.new(expense_voucher)
    if @expense_voucher.save
      redirect resource(@expense_voucher), :message => {:notice => "ExpenseVoucher was successfully created"}
    else
      message[:error] = "Expense Voucher failed to be created"
      render :new
    end
  end

  def update(id, expense_voucher)
    @expense_voucher = ExpenseVoucher.get(id)
    raise NotFound unless @expense_voucher
    if @expense_voucher.update(expense_voucher)
       redirect resource(@expense_voucher)
    else
      display @expense_voucher, :edit
    end
  end

  def destroy(id)
    @expense_voucher = ExpenseVoucher.get(id)
    raise NotFound unless @expense_voucher
    if @expense_voucher.destroy
      redirect resource(:expense_vouchers)
    else
      raise InternalServerError
    end
  end

end # ExpenseVouchers
