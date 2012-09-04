class BankBranches < Application

  def create
    @bank = Bank.get(params[:bank_id])
    @bank_branch =  @bank.bank_branches.new(:name => params[:name], :created_by_user_id => session.user.id, :biz_location_id => params[:biz_location_id])
    if @bank_branch.save
      redirect resource(@bank), :message => {:notice => "Bank Branch: #{@bank_branch.name} created successfully"}
    else
      redirect resource(@bank), :message => {:error => @bank_branch.errors.first.join(', ')}
    end
  end

  def show
    @bank_branch = BankBranch.get params[:id]
    @bank_accounts =  @bank_branch.bank_accounts
    display @bank_branch
  end
  
end
