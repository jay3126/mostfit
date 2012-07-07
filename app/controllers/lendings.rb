class Lendings < Application

  def index
    @new_lendings      = Lending.all(:status => [:new_loan_status])
    @approve_lendings  = Lending.all(:status => [:approved_loan_status])
    @disburse_lendings = Lending.all(:status => [:disbursed_loan_status])
    @fee_lendings      = Lending.all.collect{|al| al.unpaid_loan_fees}.flatten
    display @new_lendings
  end

  def new
    @lending_product  = LendingProduct.get params[:lending_product_id]
    @loan_borrower    = Client.get params[:client_id]
    @counterparty_ids = ClientAdministration.all.aggregate(:counterparty_id)
    @location         = BizLocation.get params[:biz_location_id] unless params[:biz_location_id].blank?
    client_facade     = FacadeFactory.instance.get_instance(FacadeFactory::CLIENT_FACADE, session.user.id)
    @clients          = @location.blank? ? Client.all(:id => @counterparty_ids) : client_facade.get_clients_administered(@location.id, get_effective_date)
    @lending          = @lending_product.lendings.new
    display @lending_product
  end

  def create
    #INITIALIZING VARIABLES USED THOURGHTOUT
    @message = {}

    #GET-KEEPING
    lending_product_id            = params[:lending_product_id]
    lan_id                        = params[:lending][:lan]
    applied_date                  = params[:lending][:applied_on_date]
    applied_by_staff              = params[:lending][:applied_by_staff]
    schedule_disbursal_date       = params[:lending][:scheduled_disbursal_date]
    schedule_first_repayment_date = params[:lending][:scheduled_first_repayment_date]
    loan_purpose_id               = params[:lending][:loan_purpose]
    loan_borrower_id              = params[:loan_borrower]
    recorded_by_user              = session.user.id
    
    @loan_borrower                = Client.get loan_borrower_id unless loan_borrower_id.blank?
    @lending_product              = LendingProduct.get lending_product_id unless lending_product_id.blank?

    # VALIDATIONS
    @message[:error] = "Loan Id cannot blank" if lan_id.blank?
    @message[:error] = "Applied Date cannot blank" if applied_date.blank?
    @message[:error] = "Please select staff" if applied_by_staff.blank?
    @message[:error] = "Schedule Disbursal Date cannot blank" if schedule_disbursal_date.blank?
    @message[:error] = "Schedule First Repayment Date cannot blank" if schedule_first_repayment_date.blank?
    @lending = @lending_product.lendings.new(params[:lending])

    # PERFORM OPERATION
    if @message[:error].blank?
      begin
        @client_admin = ClientAdministration.first :counterparty_type => 'client', :counterparty_id => @loan_borrower.id
        money_amount  = @lending_product.to_money[:amount]
        @loan_purpose = LoanPurpose.get loan_purpose_id
        @lending       = Lending.create_new_loan(money_amount, @lending_product.repayment_frequency.to_s, @lending_product.tenure, @lending_product,
          @loan_borrower, @client_admin.administered_at, @client_admin.registered_at, applied_date, schedule_disbursal_date,
          schedule_first_repayment_date, applied_by_staff, recorded_by_user, lan_id, @loan_purpose)

        if @lending.new?
          @message[:error] = @lending.error.first.join(", ")
        else
          @message[:notice] = "Lending created successfully"
        end
      rescue => ex
        @message = {:error => "An error has occured: #{ex.message}"}
      end
    end

    #REDIRECTION/RENDER
    if @message[:error].blank?
      redirect resource(@lending), :message => @message
    else
      render :new
    end
    
  end

  def show
    @lending           = Lending.get params[:id]
    @lending_product   = @lending.lending_product
    @effective_date    = get_effective_date
    @lending_schedules = @lending.loan_base_schedule.base_schedule_line_items
    display @lending
  end


  def edit
  end

  def update
  end

  def update_lending_new_to_approve
    @message       = {}
    lendings       = []
    save_lendings  = 0
    lending_params = params[:lending]
    begin
      lending_params.each do |key, value|
        if value.size == 2
          lending                   = Lending.get key
          approve_amount            = MoneyManager.get_money_instance(value.last[:approved_amount])
          lending.approved_amount   = approve_amount.amount
          lending.approved_by_staff = value.last[:approved_by_staff]
          lending.approved_on_date  = value.last[:approved_on_date]
          if lending.valid?
            lendings << lending
          else
            @message = {:error => "#{lending.id}= #{lending.errors.first.join(', ')}"}
          end
        end
      end
      if @message[:error].blank?
        lendings.each do |lending|
          params[:submit] == 'Reject' ? lending.reject() : lending.approve(lending.to_money[:approved_amount], lending.approved_on_date, lending.approved_by_staff)
          save_lendings = save_lendings +  1 if lending.reload.is_approved?
        end
      end
    rescue => ex
      @message = {:error => "An error has occured: #{ex.message}"}
    end

    if @message.blank?
      if lendings.blank?
        @message = {:error => "Please select loan for approve/reject"}
      elsif lendings.count != save_lendings
        @message = {:error => "Loan #{params[:submit].downcase}ed fail."}
      else
        @message = {:notice => "Loan #{params[:submit].downcase}ed successfully."}
      end
    end

    redirect resource(:lendings) , :message => @message
  end

  def update_lending_approve_to_disburse
    @message       = {}
    lendings       = []
    lending_params = params[:lending]
    begin
      lending_params.each do |key, value|
        if value.size == 2
          lending                    = Lending.get key
          disbursed_amount           = MoneyManager.get_money_instance(value.last[:disbursed_amount])
          lending.disbursed_amount   = disbursed_amount.amount
          lending.disbursed_by_staff = value.last[:disbursed_by_staff]
          lending.disbursal_date     = value.last[:disbursal_date]
          if lending.valid?
            lendings << lending
          else
            @message = {:error => "#{lending.id}= #{lending.errors.first.join(', ')}"}
          end
        end
      end
      @message = {:error => "Please select loan for disburse"} if lendings.blank?
      if @message[:error].blank?
        lendings.each do |lending|
          payment_facade.record_payment(lending.to_money[:disbursed_amount], 'payment', Constants::Transaction::PAYMENT_TOWARDS_LOAN_DISBURSEMENT, 'lending', lending.id, 'client', lending.loan_borrower.counterparty_id, lending.administered_at_origin, lending.accounted_at_origin, lending.disbursed_by_staff, lending.disbursal_date, Constants::Transaction::LOAN_DISBURSEMENT)
          if lending.is_outstanding?
            @message = {:notice => "Loans disbursed successfully."}
          else
            @message = {:error => "Loan disbursement failed."}
          end
        end
      end
    rescue => ex
      @message = {:error => "An error has occured: #{ex.message}"}
    end

    redirect resource(:lendings) , :message => @message
  end

  def payment_on_disburse_loan
    @message       = {}
    payments       = []
    lending_params = params[:lending]
    begin
      lending_params.each do |key, value|
        if value.size == 2
          lending          = Lending.get key
          payment_amount   = MoneyManager.get_money_instance(value.last[:payment_amount])
          payment_by_staff = value.last[:payment_by_staff]
          payment_on_date  = value.last[:payment_on_date]
          payments << {:lending => lending, :payment_amount => payment_amount, :payment_by_staff => payment_by_staff, :payment_on_date => payment_on_date }
        end
      end
      @message = {:error => "Please select loan for repayment"} if payments.blank?
      if @message[:error].blank?
        payments.each do |payment|
          lending         = payment[:lending]
          payment_facade.record_payment(payment[:payment_amount], 'receipt', Constants::Transaction::PAYMENT_TOWARDS_LOAN_REPAYMENT, 'lending', lending.id, 'client', lending.loan_borrower.counterparty_id, lending.administered_at_origin, lending.accounted_at_origin, payment[:payment_by_staff], payment[:payment_on_date], Constants::Transaction::LOAN_REPAYMENT)
          @message = {:notice => "Loan repayment done successfully."}
        end
      end
    rescue => ex
      @message = {:error => "An error has occured: #{ex.message}"}
    end

    if @message[:error].blank?
      redirect resource(:payment_transactions, :lending_ids => payments.collect{|p| p[:lending].id} ) , :message => @message
    else
      redirect resource(:lendings), :message => @message
    end
  end

  def lending_transactions
    @lending              = Lending.get params[:id]
    @lending_transactions = PaymentTransaction.all(:on_product_type =>'lending' ,:on_product_id => @lending.id)
    partial 'lending_transactions'
  end

  def create_repayment_on_lending
    # INITIALIZING OF VARIABLES USED THROUGHTOUT
    @message = {}

    # GET-KEEPING
    @lending         = Lending.get params[:id]
    payment_amount   = params[:payment_amount]
    payment_type     = params[:payment_type]
    payment_towards = Constants::Transaction::PAYMENT_TOWARDS_LOAN_REPAYMENT
    payment_date     = params[:payment_date]
    payment_by_staff = params[:payment_by_staff]

    #VALIDATION
    @message[:error] = "Payment amount cannot be blank" if payment_amount.blank?
    @message[:error] = "Please enter valid value of amount" if payment_amount.to_f <= 0

    #OPREATION
    if @message[:error].blank?
      begin
        money_amount    = MoneyManager.get_money_instance(payment_amount)
        payment_facade.record_payment(money_amount, payment_type, payment_towards, 'lending', @lending.id, 'client', @lending.borrower.id, @lending.administered_at_origin, @lending.accounted_at_origin, payment_by_staff, payment_date, Constants::Transaction::LOAN_REPAYMENT)
        @message = {:notice => "Loan payment saved successfully."}
      rescue => ex
        @message = {:error => "An error has occured: #{ex.message}"}
      end
    end
    
    #REDIRECT/RENDER
    redirect url("lendings/#{params[:id]}"), :message => @message
  end

  def lending_status_history
    @lending = Lending.get params[:id]
    @lending_status_changes = LoanStatusChange.all(:lending_id => @lending.id)
    partial 'lendings/lending_status_history'
  end

  def lending_due_statuses
    @lending = Lending.get params[:id]
    @lending_due_statuses = @lending.loan_due_statuses
    partial 'lendings/lending_due_status'
  end

  def lending_accrual_transaction
    @lending = Lending.get params[:id]
    @lending_accrual_transactions = AccrualTransaction.all(:on_product_type => 'lending', :on_product_id => @lending.id)
    partial 'lendings/lending_accrual'
  end

  def lending_preclose
    # INITIALIZATIONS
    lending_id = params[:id]
    raise NotFound, "Id not found" if lending_id.blank?
    @lending = Lending.get lending_id
    display @lending
  end
  
  def record_lending_preclose
    # INITIALIZATIONS
    @errors = []
    @lending = Lending.get params[:loan_id]

    # GATE-KEEPING
    receipt_type = params[:receipt_type]
    payment_towards = params[:payment_towards]
    on_product_type = params[:on_product_type]
    on_product_id = params[:on_product_id]
    by_counterparty_type = params[:by_counterparty_type]
    by_counterparty_id = params[:by_counterparty_id]
    performed_at = params[:performed_at]
    accounted_at = params[:accounted_at]
    performed_by = params[:performed_by]
    effective_on = params[:effective_on]
    product_action = params[:product_action]
    make_specific_allocation = true
    specific_principal_amount = params[:specific_principal_amount]
    specific_principal_money_amount = MoneyManager.get_money_instance(specific_principal_amount)
    specific_interest_amount = params[:specific_interest_amount]
    specific_interest_money_amount =  MoneyManager.get_money_instance(specific_interest_amount)
    total_money_amount = specific_principal_money_amount + specific_interest_money_amount

    # VALIDATIONS
    @errors << "Preclosure date must not be future date" if Date.parse(effective_on) > Date.today
    # OPERATIONS
    if @errors.blank?
      begin
        payment_facade.record_payment(total_money_amount, receipt_type.to_sym, payment_towards.to_sym, on_product_type, on_product_id, by_counterparty_type, by_counterparty_id, performed_at, accounted_at, performed_by, effective_on, product_action.to_sym, make_specific_allocation, specific_principal_money_amount, specific_interest_money_amount)
        message = {:notice => "Succesfully preclosed"}
      rescue => ex
        message = {:error => ex.message}
      end
      redirect url("lendings/#{@lending.id}"), :message => message
    else
      redirect url("lendings/lending_preclose/#{@lending.id}"), :message => {:error => @errors.flatten.join(' ,')}
    end
  end

  def save_lendings_fee
    @message           = {}
    fee_infos          = []
    fee_lending_params = params[:fee_lending]
    begin
      fee_lending_params.each do |key, value|
        if value.size == 2
          fee          = FeeInstance.get key
          fee_by_staff = value.last[:fee_by_staff]
          fee_on_date  = value.last[:fee_on_date]
          fee_amt      = fee.effective_total_amount(get_effective_date)
          fee_info     = FeeReceiptInfo.new(fee, fee_amt, fee_by_staff, fee_on_date)
          fee_infos    << fee_info
        end
      end
      @message = {:error => "Please select Fee for payment"} if fee_infos.blank?
      if @message[:error].blank?
        payment_facade.record_fee_receipts(fee_infos)
        @message = {:notice => "Loan fee payment done successfully."}
      end
    rescue => ex
      @message = {:error => "An error has occured: #{ex.message}"}
    end
    redirect resource(:lendings), :message => @message
  end

end