class MoneyDeposits < Application

  def index
    @money_deposits = MoneyDeposit.all(:order => [:created_on.desc])
    @branch_id = params[:branch_id]
    render :layout => layout?
  end

  def create
    # INITIALIZING VARIABLES USED THROUGHOUT
    @errors = []

    # GATE-KEEPING
    account = params[:account]
    amount = params[:amount]
    by_staff = params[:by_staff_id]
    created_on = params[:created_on]
    @account = BankAccount.get(account)

    # VALIDATIONS
    @errors << "Amount must not be blank " if amount.blank?
    @errors << "Staff member must not be blank" if by_staff.blank?
    @errors << "Account not found" if @account.blank?

    # OPERATIONS PERFORMED
    if @errors.blank?
      @money = MoneyManager.get_money_instance(amount)
      @money_deposit = MoneyDeposit.record_money_deposit(@money, @account.id, created_on, by_staff, session.user.id)

      if @money_deposit
        message = {:notice => "Save Successfully"}
      else
        message = {:error => "#{@money_deposit.errors.first.to_s}"}
      end
    else
      message = {:error => "No data passed."}
    end
    
    # REDIRECTIONS
    if params[:branch_id].blank?
      redirect :index, :message => message
    else
      redirect url("branches/#{params[:branch_id]}#bank_deposits"), :message => message
    end

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

  def mark_verification
    @money_deposit = MoneyDeposit.get(params[:id])
    display @money_deposit
  end

  def record_verification
    # INITIALIZING VARIABLES USED THROUGHTOUT
    @errors = []

    # GATE-KEEPING
    id = params[:money_deposit_id]
    verification_status = params[:verification_status]
    verified_by = params[:verified_by_staff_id]
    verified_on = params[:verified_on]

    # VALIDATIONS
    @errors << "Verification status must not be blank" if verification_status.blank?
    @errors << "Verified by staff member must not be blank" if verified_by.blank?
    @errors << "Verified on date must not be future date" if Date.parse(verified_on) > Date.today

    # OPERATIONS-PERFORMED
    if @errors.blank?
      begin
        @money_deposit = MoneyDeposit.get(id)
        is_saved = @money_deposit.update(:verification_status => params[:verification_status], :verified_on => params[:verified_on], :verified_by_staff_id => params[:verified_by] )
        if is_saved
          message = {:notice => "Verification status successfuly marked"}
        else
          message = {:notice => @errors.to_s}
        end
      rescue => ex
        @errors.push(ex.message)
      end
      redirect "index", :message => message
    else
      # RENDER/RE-DIRECT
      redirect "mark_verification", :message => {:error => @errors.to_a.flatten.join(', ')}
    end
  end

end