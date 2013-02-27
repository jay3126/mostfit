class BankAccounts < Application

  def create
    @bank_branch = BankBranch.get(params[:branch_id])
    @bank_account =  @bank_branch.bank_accounts.new(:name => params[:name], :account_no => params[:account_no], :created_by_user_id => session.user.id)
    if @bank_account.save
      redirect resource(@bank_branch.bank,@bank_branch), :message => {:notice => "Bank Account: #{@bank_account.name} created successfully"}
    else
      redirect resource(@bank_branch.bank,@bank_branch), :message => {:error => "Bank Account failed to be created because: #{@bank_account.errors.instance_variable_get("@errors").map{|k, v| v.join(", ")}.join(", ")}"}
    end
  end

  def show
    @bank_account = BankAccount.get params[:id]
    @money_deposits =  @bank_account.money_deposits
    display @bank_account
  end
end
