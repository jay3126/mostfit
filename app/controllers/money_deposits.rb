class MoneyDeposits < Application

  def index
    @money_deposits = MoneyDeposit.all(:order => [:created_on.desc])
    render :layout => layout?
  end

  def create
    @branch = Branch.get(params[:branch_id])
    @account = BankAccount.get params[:account]
    unless @account.nil? || @branch.nil?
      @money_deposit = @account.money_deposits.new(:amount => params[:amount], :created_by_user_id => session.user.id, :created_by_staff_id => params[:by_staff_id], :created_on => params[:created_on])
      if @money_deposit.save
        message = {:notice => "Save Successfully"}
      else
        message = {:error => "#{@money_deposit.errors.first.to_s}"}
      end
    else
      message = {:error => "No data passed."}
    end
    redirect url("branches/#{@branch.id}#bank_deposits"), :message => message
  end

  def get_bank_branches
    if params[:bank_id]
      bank = Bank.get(params[:bank_id])
      return("<option value=''>Select branch</option>") unless bank
      bank_branches = bank.bank_branches
      return("<option value=''>Select branch</option>"+bank_branches.map{|b| "<option value=#{b.id}>#{b.name}</option>"}.join)
    end
  end

  def get_bank_accounts
    if params[:branch_id]
      bank_branch = BankBranch.get(params[:branch_id])
      return("<option value=''>Select account</option>") unless bank_branch
      bank_accounts = bank_branch.bank_accounts
      return("<option value=''>Select account</option>"+bank_accounts.map{|b| "<option value=#{b.id}>#{b.name}-#{b.account_no}</option>"}.join)
    end
  end

end
