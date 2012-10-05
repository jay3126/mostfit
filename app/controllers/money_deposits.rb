class MoneyDeposits < Application

  def index
    @money_deposits = MoneyDeposit.all(:at_location_id => params[:at_location_id], :order => [:created_on.desc])
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
    at_location_id = params[:at_location_id]

    @account = BankAccount.get(account)

    # VALIDATIONS
    @errors << "Amount must not be blank " if amount.blank?
    @errors << "Staff member must not be blank" if by_staff.blank?
    @errors << "Account not found" if @account.blank?

    # OPERATIONS PERFORMED
    if @errors.blank?
      begin
        @money = MoneyManager.get_money_instance(amount)
        @money_deposit = MoneyDeposit.record_money_deposit(@money, @account.id, created_on, by_staff, session.user.id, at_location_id)

        if @money_deposit
          message = {:notice => "Save Successfully"}
        else
          message = {:error => "#{@money_deposit.errors.first.to_s}"}
        end
      rescue => ex
        message = {:error => ex.message }
      end
    end

    # REDIRECTIONS
    if at_location_id.blank?
      redirect "/money_deposits", :message => message
    else
      redirect url("user_locations/show/#{at_location_id}#money_deposits"), :message => message
    end

  end

  def mark_verification
    @at_location_id = params[:at_location_id]
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
    @at_location_id = params[:at_location_id]

    # VALIDATIONS
    @errors << "Verification status must not be blank" if verification_status.blank?
    @errors << "Verified by staff member must not be blank" if verified_by.blank?
    @errors << "Verified on date must not be future date" if Date.parse(verified_on) > Date.today
    @money_deposit = MoneyDeposit.get(id)

    # OPERATIONS-PERFORMED
    if @errors.blank?
      begin
        is_saved = @money_deposit.update(:verification_status => verification_status, :verified_on => verified_on, :verified_by_staff_id => verified_by)
        if is_saved
          message = {:notice => "Verification status successfuly marked"}
        else
          message = {:notice => @errors.to_s}
        end
      rescue => ex
        @errors.push(ex.message)
      end
      redirect url("user_locations/show/#{@at_location_id}#money_deposits"), :message => message
    else
      # RENDER/RE-DIRECT
      redirect url("money_deposits/mark_verification/#{id}?at_location_id=#{@at_location_id}"), :message => {:error => @errors.to_a.flatten.join(', ')}
    end
  end

  def get_bank_branches
    if params[:bank_id]
      bank         = Bank.get(params[:bank_id])
      biz_location = BizLocation.get(params[:biz_location_id])
      return("<option value=''>Select branch</option>") if bank.blank? || biz_location.blank?
      bank_branches = biz_location.bank_branches(:bank_id => params[:bank_id])
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

  def get_money_deposits
    @money_deposits = []
    @date = params[:on_date].blank? ? get_effective_date : params[:on_date]
    if params[:submit]
      if params[:location_ids].blank?
        @money_deposits = MoneyDeposit.all(:created_on => @date, :order => [:created_on.desc])
      else
        @money_deposits = MoneyDeposit.all(:at_location_id => params[:location_ids], :created_on => @date, :order => [:created_on.desc])
      end
    end
    display @money_deposits
  end

  def bulk_record_varification
    # INITIALIZING VARIABLES USED THROUGHTOUT
    @message = {:error => [], :notice => []}

    # GATE-KEEPING
    money_deposit      = params[:money_deposit]
    verification_status = money_deposit[:verification_status]
    verified_by = money_deposit[:performed_by]
    verified_on = money_deposit[:on_date]
    @location_ids = params[:location_ids]

    # VALIDATIONS
    @message[:error] << "Verification status must not be blank" if verification_status.blank?
    @message[:error] << "Verified by staff member must not be blank" if verified_by.blank?
    @message[:error] << "Verified on date must not be future date" if Date.parse(verified_on) > Date.today
    @message[:error] << "Please select Money Deposit for Varification" if money_deposit[:varified].blank?

    # OPERATIONS-PERFORMED
    if @message[:error].blank?
      begin
        money_deposit_ids = money_deposit[:varified]
        debugger
        is_saved = MoneyDeposit.all(:id => money_deposit_ids).update(:verification_status => verification_status, :verified_on => verified_on, :verified_by_staff_id => verified_by)
        if is_saved
          @message = {:notice => "Verification status successfuly marked"}
        else
          @message[:error] << @errors.to_s
        end
      rescue => ex
        @message[:error] << ex.message
      end
    end
    
    # RENDER/RE-DIRECT
    @message[:error].blank? ? @message.delete(:error) : @message.delete(:notice)
    redirect resource(:money_deposits, :get_money_deposits, :on_date => verified_on, :location_ids => @location_ids, :submit => 'Go'), :message => @message
  end
  
end