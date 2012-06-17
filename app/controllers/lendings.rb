class Lendings < Application

  def index
    @new_lendings      = Lending.all(:status => [:new_loan_status])
    @approve_lendings  = Lending.all(:status => [:approved_loan_status])
    @disburse_lendings = Lending.all(:status => [:disbursed_loan_status])
    display @new_lendings
  end

  def new
    @lending_product  = LendingProduct.get params[:lending_product_id]
    @loan_borrower    = Client.get params[:client_id]
    @counterparty_ids = ClientAdministration.all.aggregate(:counterparty_id)
    @clients          = Client.all(:id => @counterparty_ids)
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
        @lending       = Lending.create_new_loan(money_amount, @lending_product.repayment_frequency.to_s, @lending_product.tenure, @lending_product,
          @loan_borrower, @client_admin.administered_at, @client_admin.registered_at, applied_date, schedule_disbursal_date,
          schedule_first_repayment_date, applied_by_staff, recorded_by_user, lan_id)

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
          save = params[:submit] == 'Reject' ? lending.reject() : lending.approve(lending.to_money[:approved_amount], lending.approved_on_date, lending.approved_by_staff)
          save =+ 1 if save
          save_lendings =+ 1 if save
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
        mf = FacadeFactory.instance.get_instance(FacadeFactory::PAYMENT_FACADE, session.user.id)
        lendings.each do |lending|
          mf.record_payment(lending.to_money[:disbursed_amount], 'payment', 'lending', lending.id, 'client', lending.loan_borrower.counterparty_id, lending.administered_at_origin, lending.accounted_at_origin, lending.disbursed_by_staff, lending.disbursal_date, Constants::Transaction::LOAN_DISBURSEMENT)
          if lending.status == :disbursed_loan_status
            @message = {:notice => "Loans disbursed successfully."}
          else
            @message = {:error => "Loans desbursed fails."}
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
        mf = FacadeFactory.instance.get_instance(FacadeFactory::PAYMENT_FACADE, session.user.id)
        payments.each do |payment|
          lending         = payment[:lending]
          repayment_count = lending.loan_receipts.count
          mf.record_payment(payment[:payment_amount], 'receipt', 'lending', lending.id, 'client', lending.loan_borrower.counterparty_id, lending.administered_at_origin, lending.accounted_at_origin, payment[:payment_by_staff], payment[:payment_on_date], Constants::Transaction::LOAN_REPAYMENT)
          raise Errors::OperationNotSupportedError, "Operation Repayment is currently not supported" if repayment_count == lending.loan_receipts.count
          @message = {:notice => "Loans payments successfully."}
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
    payment_date     = params[:payment_date]
    payment_by_staff = params[:payment_by_staff]
    mf               = FacadeFactory.instance.get_instance(FacadeFactory::PAYMENT_FACADE, session.user.id)

    #VALIDATION
    @message[:error] = "Payment amount cannot be blank" if payment_amount.blank?
    @message[:error] = "Please enter valid value of amount" if payment_amount.to_f <= 0

    #OPREATION

    if @message[:error].blank?
      begin
        repayment_count = @lending.loan_receipts.count
        money_amount    = MoneyManager.get_money_instance(payment_amount)
        mf.record_payment(money_amount, payment_type, 'lending', @lending.id, 'client', @lending.borrower.id, @lending.administered_at_origin, @lending.accounted_at_origin, payment_by_staff, payment_date, Constants::Transaction::LOAN_REPAYMENT)
        raise Errors::OperationNotSupportedError, "Operation Repayment is currently not supported" if repayment_count == @lending.loan_receipts.count
        @message = {:notice => "Loan payment saved successfully."}
      rescue => ex
        @message = {:error => "An error has occured: #{ex.message}"}
      end
    end
    
    #REDIRECT/RENDER
    if @message[:error].blank?
      redirect resource(:payment_transactions, :lending_ids => [@lending.id]), :message => @message
    else
      redirect resource(@lending), :message => @message
    end
  end

  def lending_due_statuses
    @lending = Lending.get params[:id]
    @lending_status_changes = LoanStatusChange.all(:loan_id => @lending.id)
    partial 'lendings/lending_status'
  end
end