class Banks < Application

  def index
    @banks =  Bank.all
    display @banks
  end

  def create
    @message = {:error => [], :notice => []}
    branch_names = []
    account_nos = []
    bank_branches = params[:bank_branch]
    bank_branches.each do |key, branch|
      branch_names << branch[:bank_brach]
      account_names = []
      branch_accounts = branch[:account]
      branch_accounts.each do |a_key, account|
        account_names << account[:account_name]
        account_nos << account[:account_no]
      end
      @message[:error] << 'Account Name must be unique with in Bank Branch' if account_names.uniq.size != account_names.size
    end
    @message[:error] << 'Account No. must be unique with in Bank' if account_nos.uniq.size != account_nos.size
    @message[:error] << "Bank Branch Name must be uniqe" if branch_names.uniq.size != branch_names.size
    @bank = Bank.new(:name => params[:name], :created_by_user_id => session.user.id)
    if @message[:error].blank?
      if @bank.save
        bank_branches.each do |key, branch|
          branch_accounts = branch[:account]
          accounts = []
          branch_obj = @bank.bank_branches.new(:name => branch[:bank_branch], :created_by_user_id => session.user.id, :biz_location_id => branch[:location])
          branch_accounts.each do |a_key, account|
            branch_obj.bank_accounts.new(:name=> account[:account_name], :account_no => account[:account_no], :created_by_user_id => session.user.id) if !account[:account_name].blank? && !account[:account_no].blank?
          end
          branch_obj.save unless branch[:bank_branch].blank?
        end
        @message[:notice] = "Bank: #{@bank.name} successfully"
      else
        @message[:error] = @bank.errors.first.join(', ')
      end
    end

    if @message[:error].blank?
      redirect resource(@bank), :message => {:notice => "Bank: #{@bank.name} created successfully"}
    else
      redirect resource(:banks), :message => {:error => @message[:error]}
    end
  end

  def show
    @bank = Bank.get params[:id]
    @bank_branches = @bank.bank_branches
    display @bank
  end
  
end
