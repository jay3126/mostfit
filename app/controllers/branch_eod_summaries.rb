class BranchEodSummaries < Application

  def index
    @money_deposits = MoneyDeposit.all
    display @money_deposits
  end

  def show(id)
    @money_deposit = MoneyDeposit.get(:bank_account_id=>id)
    raise NotFound unless @money_deposit
    display @money_deposit
  end

  def new
    only_provides :html
    @branch_eod_summary = BranchEodSummary.new
    display @branch_eod_summary
  end

  def edit(id)
    only_provides :html
    @branch_eod_summary = BranchEodSummary.get(id)
    raise NotFound unless @branch_eod_summary
    display @branch_eod_summary
  end

  def create(branch_eod_summary)
    @branch_eod_summary = BranchEodSummary.new(branch_eod_summary)
    if @branch_eod_summary.save
      redirect resource(@branch_eod_summary), :message => {:notice => "BranchEodSummary was successfully created"}
    else
      message[:error] = "BranchEodSummary failed to be created"
      render :new
    end
  end

  def update(id, branch_eod_summary)
    @branch_eod_summary = BranchEodSummary.get(id)
    raise NotFound unless @branch_eod_summary
    if @branch_eod_summary.update(branch_eod_summary)
      redirect resource(@branch_eod_summary)
    else
      display @branch_eod_summary, :edit
    end
  end

  def destroy(id)
    @branch_eod_summary = BranchEodSummary.get(id)
    raise NotFound unless @branch_eod_summary
    if @branch_eod_summary.destroy
      redirect resource(:branch_eod_summaries)
    else
      raise InternalServerError
    end
  end
  
end # BranchEodSummaries
