class BankBranches < Application

  def create
    if params[:bank_branch]
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
      @bank = Bank.get(params[:bank_id])
      if @message[:error].blank?
        bank_branches.each do |key, branch|
          branch_accounts = branch[:account]
          accounts = []
          branch_obj = @bank.bank_branches.new(:name => branch[:bank_branch], :created_by_user_id => session.user.id, :biz_location_id => branch[:location])
          branch_accounts.each do |a_key, account|
            branch_obj.bank_accounts.new(:name=> account[:account_name], :account_no => account[:account_no], :created_by_user_id => session.user.id) if !account[:account_name].blank? && !account[:account_no].blank?
          end
          if branch_obj.save
            redirect resource(:banks), :message => {:notice => "Bank Branch: #{branch_obj.name} created successfully"}
          else
            redirect resource(:banks), :message => {:error => "Bank Branch failed to be created because: #{branch_obj.errors.instance_variable_get("@errors").map{|k, v| v.join(", ")}.join(", ")}"}
          end 
        end
      end

    else
      @bank = Bank.get(params[:bank_id])
      @bank_branch =  @bank.bank_branches.new(:name => params[:name], :created_by_user_id => session.user.id, :biz_location_id => params[:biz_location_id])
      if @bank_branch.save
        redirect resource(:banks), :message => {:notice => "Bank Branch: #{@bank_branch.name} created successfully"}
      else
        redirect resource(:banks), :message => {:error => "Bank Branch failed to be created because: #{@bank_branch.errors.instance_variable_get("@errors").map{|k, v| v.join(", ")}.join(", ")}"}
      end
    end
  end

  def show
    @bank_branch = BankBranch.get params[:id]
    @bank_accounts =  @bank_branch.bank_accounts
    display @bank_branch
  end
  
end
