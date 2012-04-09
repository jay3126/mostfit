class BankAccounts < Application

  def create
    @bank_branch = BankBranch.get(params[:branch_id])
    @bank_account =  @bank_branch.bank_accounts.new(:name => params[:name], :created_by_user_id => session.user.id)
    if @bank_account.save
      redirect resource(@bank_branch.bank,@bank_branch), :message => {:notice => "Save Successfully"}
    else
      redirect resource(@bank_branch.bank,@bank_branch), :message => {:error => "#{@bank_account.errors.first.to_s}"}
    end
  end

  def show
    @bank_account = BankAccount.get params[:id]
    @money_deposits =  @bank_account.money_deposits
    display @bank_account
  end
end
