class Lendings < Application

  def index
    @new_lendings, @approve_lendings, @disburse_lendings = []
    unless params[:parent_location_id].nil?
      if !params[:child_location_id].blank?
        @loans = LoanAdministration.get_loans_administered_by_sql(params[:child_location_id], get_effective_date).group_by{|g| [g.status, g.disbursement_mode]}
      else
        @loans = LoanAdministration.get_loans_accounted_by_sql(params[:parent_location_id], get_effective_date).group_by{|g| [g.status, g.disbursement_mode]}
      end
      @parent_location        = BizLocation.get(params[:parent_location_id])
      @loan_ids               = @loans.blank? ? [0] : @loans.map(&:id)
      @new_lendings           = @loans[[:new_loan_status, 'Not Specified' ]]||[]
      @pre_disbursal_lendings = @loans[[:approved_loan_status, 'Not Specified']]||[]
      @approved_lendings      = [@loans[[:approved_loan_status, 'Cheque']]||[], @loans[[:approved_loan_status, 'Cheque With Cash']]||[], @loans[[:approved_loan_status, 'Cash']]||[]].flatten
      @rejected_lendings      = [@loans[[:rejected_loan_status, 'Not Specified']]||[], @loans[[:rejected_loan_status, 'Cheque']]||[], @loans[[:approved_loan_status, 'Cheque With Cash']]||[], @loans[[:approved_loan_status, 'Cash']]||[]].flatten
    end
    display @new_lendings
  end

  def new
    @lending_product  = LendingProduct.get params[:lending_product_id]
    @loan_borrower    = Client.get params[:client_id]
    @location         = BizLocation.get params[:biz_location_id] unless params[:biz_location_id].blank?
    if @loan_borrower.blank?
      all_clients       = @lending_product.get_clients(get_effective_date, params[:biz_location_id])
      @clients          = all_clients.select{|c| client_facade.is_client_active?(c)}.compact
    end
    disbursal_date    = @location.blank? ? get_effective_date : @location.center_disbursal_date
    @lending          = @lending_product.lendings.new(:scheduled_disbursal_date => disbursal_date)
    display @lending_product
  end

  def create
    #INITIALIZING VARIABLES USED THOURGHTOUT
    @message = {:error => [], :notice => []}

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
    funding_line_id               = params[:funding_line_id]
    tranch_id                     = params[:tranch_id]

    @loan_borrower                = Client.get loan_borrower_id unless loan_borrower_id.blank?
    @lending_product              = LendingProduct.get lending_product_id unless lending_product_id.blank?
    @client_admin                 = ClientAdministration.first :counterparty_type => 'client', :counterparty_id => @loan_borrower.id
    @biz_location                 = @client_admin.administered_at_location

    # VALIDATIONS
    @message[:error] << "Loan Id cannot blank" if lan_id.blank?
    @message[:error] << "Applied Date cannot blank" if applied_date.blank?
    @message[:error] << "Please select staff" if applied_by_staff.blank?
    @message[:error] << "Schedule Disbursal Date cannot blank" if schedule_disbursal_date.blank?
    @message[:error] << "Schedule First Repayment Date cannot blank" if schedule_first_repayment_date.blank?
    @message[:error] << "Funding line cannot be blank" if funding_line_id.blank?
    @message[:error] << "Tranch cannot be blank" if tranch_id.blank?
    @message[:error] << "Applied cannot be holiday" if !applied_date.blank? && LocationHoliday.working_holiday?(@biz_location, applied_date)
    @message[:error] << "Schedule Disbursal Date cannot be holiday" if !schedule_disbursal_date.blank? && LocationHoliday.working_holiday?(@biz_location, schedule_disbursal_date)
    @message[:error] << "Schedule First Repayment Date cannot be holiday" if !schedule_first_repayment_date.blank? && LocationHoliday.working_holiday?(@biz_location, schedule_first_repayment_date)

    @lending = @lending_product.lendings.new(params[:lending])

    # PERFORM OPERATION
    if @message[:error].blank?
      begin
        money_amount  = @lending_product.to_money[:amount]
        @loan_purpose = LoanPurpose.get loan_purpose_id
        @lending       = Lending.create_new_loan(money_amount, @lending_product.repayment_frequency.to_s, @lending_product.tenure, @lending_product,
          @loan_borrower, @client_admin.administered_at, @client_admin.registered_at, applied_date, schedule_disbursal_date,
          schedule_first_repayment_date, applied_by_staff, recorded_by_user, funding_line_id, tranch_id, lan_id, @loan_purpose)

        if @lending.new?
          @message[:error] << @lending.error.first.join("<br>")
        else
          @message[:notice] = "Loan (Id: #{@lending.id}) created successfully"
        end
      rescue => ex
        @message[:error] << "An error has occured: #{ex.message}"
      end
    end

    #REDIRECTION/RENDER
    @message[:error].blank? ? @message.delete(:error) : @message.delete(:notice)
    if @message[:error].blank?
      redirect resource(@lending), :message => @message
    else
      render :new
    end
    
  end

  def show
    @lending                = Lending.get params[:id]
    @lending_product        = @lending.lending_product
    @effective_date         = get_effective_date
    @lending_schedules      = @lending.loan_base_schedule.base_schedule_line_items rescue nil
    @fee_instance           = FeeInstance.get_all_fees_for_instance(@lending)
    @lending_status         = @lending.loan_status_changes.last
    display @lending
  end

  def update_lending_new_to_approve
    @message          = {:error => [], :notice => []}
    lendings          = []
    lending_params    = params[:lending]
    approved_by_staff = params[:approved_by_staff]
    approved_on_date  = Date.parse params[:approved_on_date]
    reason_id         = params[:reason]
    remarks           = params[:remarks]
    recorded_by       = session.user.id
    @message[:error] << "Please select Staff Member" if approved_by_staff.blank?
    @message[:error] << "Approve Date cannot blank" if approved_on_date.blank?
    @message[:error] << "Please select Reason" if params[:submit] == 'Reject' && reason_id.blank?
    @message[:error] << "Remarks cannot be blank" if params[:submit] == 'Reject' && remarks.blank?
    @message[:error] << "Please select loans for Approve or Reject" if lending_params.values.select{|l| l[:approve]}.count <= 0
    
    if @message[:error].blank?
      begin
        lending_params.each do |key, value|
          unless value[:approve].blank?
            lending                   = Lending.get key
            approve_amount            = MoneyManager.get_money_instance(value[:approved_amount])
            lending.approved_amount   = approve_amount.amount
            lending.approved_by_staff = approved_by_staff
            lending.approved_on_date  = approved_on_date
            if lending.valid?
              lendings << lending
            else
              @message[:error] << "Loan (#{lending.id}):- #{lending.errors.first.join('<br>')}"
            end
          end
        end
        if @message[:error].blank?
          lendings.each do |lending|
            if params[:submit] == 'Reject'
              lending.reject(approved_on_date, approved_by_staff)
              Comment.save_comment(remarks, reason_id, 'Lending', lending.id, recorded_by)
            else
              lending.approve(lending.to_money[:approved_amount], approved_on_date, approved_by_staff)
            end
          end
        end
      rescue => ex
        @message[:error] << "An error has occured: #{ex.message}"
      end
    end

    @message = {:notice => "Loan #{params[:submit].downcase}ed successfully."} if @message[:error].blank?
    @message[:error].blank? ? @message.delete(:error) : @message.delete(:notice)
    redirect resource(:lendings, :parent_location_id => params[:parent_location_id], :child_location_id => params[:child_location_id]) , :message => @message
  end


  def setup_lending_disbursement_mode
    @message           = {:error => [], :notice => []}
    lendings           = {}
    lending_params     = params[:lending]
    performed_by_staff = params[:performed_by_staff]
    recorded_by        = session.user.id
    cheque_numbers = lending_params.values.map{|l| l[:cheque_number] if ['Cheque', 'Cheque With Cash'].include?(l[:disbursement_mode]) && !l[:disbursement].blank?}
    @message[:error] << "Please select Staff Member" if performed_by_staff.blank?
    @message[:error] << "Please select loans for Setup Disbursement Mode" if lending_params.values.select{|l| l[:disbursement]}.count <= 0
    @message[:error] << "A Cheque No. cannot be use multiple times" if !cheque_numbers.blank? && cheque_numbers.compact.count != cheque_numbers.compact.uniq.count
    if @message[:error].blank?
      begin
        lending_params.each do |key, value|
          unless value[:disbursement].blank?
            lending                    = Lending.get key
            cheque_number              = value[:cheque_number]
            disbursement_mode          = value[:disbursement_mode]
            cheque_amount              = value[:cheque_amount].blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance(value[:cheque_amount])
            lending.cheque_number      = cheque_number if (cheque_number != "Not Specified" and ['Cheque', 'Cheque With Cash'].include?(disbursement_mode))
            lending.disbursement_mode  = disbursement_mode
            @message[:error] << "Loan(#{lending.id})= Please Select Disbursement Mode" if disbursement_mode.blank? || disbursement_mode == "Not Specified"
            @message[:error] << "Loan(#{lending.id})= Please Select Cheque No." if ['Cheque', 'Cheque With Cash'].include?(disbursement_mode) && cheque_number.blank?
            @message[:error] << "Loan(#{lending.id})= Cheque Amount cannot be blank" if ['Cheque', 'Cheque With Cash'].include?(disbursement_mode) && value[:cheque_amount].blank?
            @message[:error] << "Loan(#{lending.id})= Cheque Amount cannot be greater Approved Amount" if ['Cheque', 'Cheque With Cash'].include?(disbursement_mode) && cheque_amount > lending.to_money[:approved_amount]
            if lending.valid?
              lendings[lending] = {:cheque_number => cheque_number, :cheque_amount => cheque_amount}
            else
              @message[:error] << "#{lending.id}= #{lending.errors.first.join(', ')}"
            end
          end
        end
        if @message[:error].blank?
          lendings.each do |lending, cheque|
            if lending.save
              #this method will update the cheque leaf as used if disbursement mode is Cheque.
              if ['Cheque', 'Cheque With Cash'].include?(lending.disbursement_mode)
                ChequeLeaf.get(cheque[:cheque_number]).update!(:amount => cheque[:cheque_amount].amount, :currency => cheque[:cheque_amount].currency, :used => true)
              end
            else
              @message[:error] << "Loan(#{lending.id})= #{lending.errors.first.join(',')}"
            end
          end
        end
      rescue => ex
        @message[:error] << "An error has occured: #{ex.message}"
      end
    end
    @message = {:notice => "Loan saved successfully."} if @message[:error].blank?
    @message[:error].blank? ? @message.delete(:error) : @message.delete(:notice)
    redirect resource(:lendings, :parent_location_id => params[:parent_location_id], :child_location_id => params[:child_location_id]) , :message => @message
  end

  def update_lending_approve_to_disburse
    @message           = {:error => [], :notice => []}
    lendings           = []
    lending_params     = params[:lending]
    disbursed_by_staff = params[:disbursed_by_staff]
    disbursal_date     = Date.parse params[:disbursal_date]
    reason_id          = params[:reason]
    remarks            = params[:remarks]
    recorded_by        = session.user.id

    @message[:error] << "Please select Staff Member" if disbursed_by_staff.blank?
    @message[:error] << "Disbursal Date cannot blank" if disbursal_date.blank?
    @message[:error] << "Please select Reason" if params[:submit] == 'Reject' && reason_id.blank?
    @message[:error] << "Remarks cannot be blank" if params[:submit] == 'Reject' && remarks.blank?
    @message[:error] << "Please select loans for Disburse or Reject" if lending_params.values.select{|l| l[:disburse]}.count <= 0
    
    if @message[:error].blank?
      begin
        lending_params.each do |key, value|
          unless value[:disburse].blank?
            lending                    = Lending.get key
            disbursed_amount           = MoneyManager.get_money_instance(value[:disbursed_amount])
            lending.disbursed_amount   = disbursed_amount.amount
            lending.disbursed_by_staff = disbursed_by_staff
            lending.disbursal_date     = disbursal_date
            if lending.valid?
              lendings << lending
            else
              @message[:error] << "#{lending.id}= #{lending.errors.first.join(', ')}"
            end
          end
        end
        if @message[:error].blank?
          lendings.each do |lending|
            if params[:submit] == 'Reject'
              lending.reject(disbursal_date, disbursed_by_staff)
              Comment.save_comment(remarks, reason_id, 'Lending', lending.id, recorded_by)
            else
              insurance_policies = lending.simple_insurance_policies.map(&:id) rescue []
              fee_insurances     = FeeInstance.all_unpaid_loan_insurance_fee_instance(insurance_policies) unless insurance_policies.blank?
              fee_instances      = FeeInstance.all_unpaid_loan_fee_instance(lending.id)
              fee_instances      = fee_instances + fee_insurances unless fee_insurances.blank?

              payment_facade.record_payment(lending.to_money[:disbursed_amount], 'payment', Constants::Transaction::PAYMENT_TOWARDS_LOAN_DISBURSEMENT, '', 'lending', lending.id, 'client', lending.loan_borrower.counterparty_id, lending.administered_at_origin, lending.accounted_at_origin, disbursed_by_staff, disbursal_date, Constants::Transaction::LOAN_DISBURSEMENT)
              fee_instances.each do |fee_instance|
                payment_facade.record_fee_payment(fee_instance.id, fee_instance.effective_total_amount, 'receipt', Constants::Transaction::PAYMENT_TOWARDS_FEE_RECEIPT,'','lending', lending.id, 'client', lending.loan_borrower.counterparty_id, lending.administered_at_origin, lending.accounted_at_origin, disbursed_by_staff, disbursal_date, Constants::Transaction::LOAN_FEE_RECEIPT)
              end
              @message[:error].push("An error occurred disbursing loan ID: #{lending.id}") unless lending.reload.is_outstanding?
            end
          end
        end
      rescue => ex
        @message[:error] << "An error has occured: #{ex.message}"
      end
    end
    @message = {:notice => "Loan #{params[:submit].downcase}d successfully."} if @message[:error].blank?
    @message[:error].blank? ? @message.delete(:error) : @message.delete(:notice)
    redirect resource(:lendings, :parent_location_id => params[:parent_location_id], :child_location_id => params[:child_location_id]) , :message => @message
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
      redirect resource(:lendings, :parent_location_id => params[:parent_location_id], :child_location_id => params[:child_location_id]), :message => @message
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
    receipt_no       = params[:receipt_no]
    payment_type     = params[:payment_type]
    payment_date     = params[:payment_date]
    payment_by_staff = params[:payment_by_staff]
    if @lending.is_written_off?
      payment_towards  = Constants::Transaction::PAYMENT_TOWARDS_LOAN_RECOVERY
      product_action   = Constants::Transaction::LOAN_RECOVERY
    else
      payment_towards  = Constants::Transaction::PAYMENT_TOWARDS_LOAN_REPAYMENT
      product_action   = Constants::Transaction::LOAN_REPAYMENT
    end

    #VALIDATION
    @message[:error] = "Payment amount cannot be blank" if payment_amount.blank?
    @message[:error] = "Please enter valid value of amount" if payment_amount.to_f <= 0
    @message[:error] = "Payment Type cannot be blank" if payment_type.blank?
    @message[:error] = "Payment Date cannot be blank" if payment_date.blank?
    @message[:error] = "Please select Payment By Staff" if payment_by_staff.blank?

    #OPREATION
    if @message[:error].blank?
      begin
        money_amount    = MoneyManager.get_money_instance(payment_amount)
        valid = @lending.is_payment_transaction_permitted?(money_amount, payment_date, payment_by_staff, session.user.id)
        if valid == true
          payment_facade.record_payment(money_amount, payment_type, payment_towards, receipt_no, 'lending', @lending.id, 'client', @lending.borrower.id, @lending.administered_at_origin, @lending.accounted_at_origin, payment_by_staff, payment_date, product_action)
          @message = {:notice => "Loan payment saved successfully."}
        else
          @message = {:error => valid.last}
        end
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

  def bulk_lending_preclose
    @lendings        = []
    @message         = {}
    @date            = params[:date].blank? ? get_effective_date : Date.parse(params[:date])
    @biz_location_id = params[:child_location_id]
    unless params[:child_location_id].blank?
      @biz_location =  BizLocation.get @biz_location_id
      @lendings     = LoanAdministration.get_loans_administered(@biz_location.id, @date).compact.select{|l| l.is_outstanding?}
    end
    display @lendings
  end

  def check_preclosure_date
    lending_id = params[:loan_id]
    @preclose_on_date = params[:effective_on]
    @lending = Lending.get lending_id
    preclosure_penalty_product = @lending.get_preclosure_penalty_product
    @preclosure_penalty_amount = preclosure_penalty_product ? preclosure_penalty_product.effective_total_amount(@preclose_on_date) :
      MoneyManager.default_zero_money
    render :template => "lendings/lending_preclose"
  end

  def record_bulk_lending_preclose
    @message                 = {:error => [], :notice => []}
    preclose_lendings        = {}
    @staff_id                = session.user.staff_member.id
    lending_params           = params[:preclose].blank? ? [] : params[:preclose]
    parent_location_id       = params[:parent_location_id]
    child_location_id        = params[:child_location_id]
    effective_on             = params[:on_date]
    performed_by             = params[:performed_by]
    reason_id                = params[:reason]
    remarks                  = params[:remarks]
    recorded_by              = session.user.id
    receipt_type             = Constants::Transaction::RECEIPT
    payment_towards          = Constants::Transaction::PAYMENT_TOWARDS_LOAN_PRECLOSURE
    on_product_type          = 'lending'
    by_counterparty_type     = 'client'
    currency                 = 'INR'
    product_action           = Constants::Transaction::LOAN_PRECLOSURE
    make_specific_allocation = true
    parent_location = BizLocation.get parent_location_id

    @message[:error] << "Please select checkbox for Preclose loan" if lending_params.values.select{|l| l[:preclose]}.blank?
    @message[:error] << "Preclose date cannot be blank" if effective_on.blank?
    @message[:error] << "Please select Staff Member" if performed_by.blank?
    @message[:error] << "Please Enter Interest Amount Greater Than ZERO" unless lending_params.values.select{|f| f[:interest_amount].to_f < 0}.blank?
    @message[:error] << "Please Enter Amount Greater Than ZERO" unless lending_params.values.select{|f| f[:total_amount].to_f <= 0}.blank?
    @message[:error] << "Please select Reason" if reason_id.blank?
    @message[:error] << 'Remarks cannot be blank' if remarks.blank?
    @message[:error] << "Preclose Date cannot be holiday" if LocationHoliday.working_holiday?(parent_location, effective_on)

    begin
      if @message[:error].blank?
        lending_params.each do |key, value|
          unless value[:preclose].blank?
            lending                       = Lending.get value[:lending_id]
            preclose_lendings[lending.id] = {}
            by_counterparty_id            = value[:client_id]
            performed_at                  = lending.administered_at_origin
            accounted_at                  = lending.accounted_at_origin
            money_principal_amount        = MoneyManager.get_money_instance(value[:principal_amount].to_f)
            money_interest_amount         = MoneyManager.get_money_instance(value[:interest_amount].to_f)
            money_amount                  = money_principal_amount + money_interest_amount
            receipt_no                    = value[:receipt_no]
            fee_amount                    = value[:preclosure_penalty]
            fee_money_amount              = MoneyManager.get_money_instance(fee_amount)
            fee_product                   = lending.get_preclosure_penalty_product
            fee_amount                    = fee_product.blank? ? MoneyManager.default_zero_money : fee_product.effective_total_amount
            preclose_lendings[lending.id][:principal_amount] = money_principal_amount
            preclose_lendings[lending.id][:interest_amount] = money_interest_amount
            payment_transaction     = PaymentTransaction.new(:amount => money_amount.amount, :currency => currency, :effective_on => effective_on,
              :on_product_type      => on_product_type, :on_product_id  => lending.id, :receipt_no => receipt_no,
              :performed_at         => performed_at, :accounted_at   => accounted_at,
              :performed_by         => performed_by, :recorded_by    => recorded_by,
              :by_counterparty_type => by_counterparty_type, :by_counterparty_id  => by_counterparty_id,
              :receipt_type         => receipt_type, :payment_towards     => payment_towards)
            if payment_transaction.valid?
              if payment_facade.is_loan_payment_permitted?(payment_transaction)
                preclose_lendings[lending.id][:payment_transaction] = payment_transaction
              else
                @message[:error] << "#{on_product_type}(#{lending.id}) {#{payment_transaction.errors.collect{|error| error}.flatten.join(', ')}}"
              end
            end
            if fee_money_amount > fee_amount
              @message[:error] << "#{on_product_type}(#{lending.id}) {Penalty Amount is not greater than #{fee_amount}}"
            else
              preclose_lendings[lending.id][:penalty_amount] = fee_money_amount
              preclose_lendings[lending.id][:fee_product] = fee_product.blank? ? nil : fee_product
            end
          end
        end
      end
      if @message[:error].blank?
        begin
          preclose_lendings.each do |lending_id, preclose_lending|
            lending            = Lending.get lending_id
            pt                 = preclose_lending[:payment_transaction]
            principal_amount   = preclose_lending[:principal_amount]
            interest_amount    = preclose_lending[:interest_amount]
            total_money_amount = pt.to_money[:amount]
            loan_facade.adjust_advance_for_perclose(effective_on, lending.id) if lending.current_advance_available > MoneyManager.default_zero_money
            if total_money_amount > MoneyManager.default_zero_money
              payment_facade.record_payment(total_money_amount, receipt_type.to_sym, payment_towards.to_sym, pt.receipt_no, pt.on_product_type, pt.on_product_id, pt.by_counterparty_type, pt.by_counterparty_id, pt.performed_at, pt.accounted_at, performed_by, effective_on, product_action.to_sym, make_specific_allocation, principal_amount, interest_amount)
            end
            unless preclose_lending[:fee_product].blank?
              payment_facade.record_fee_payment(preclose_lending[:fee_product].id, preclose_lending[:penalty_amount], 'receipt', Constants::Transaction::PAYMENT_TOWARDS_FEE_RECEIPT, '','lending', pt.on_product_id, 'client', pt.by_counterparty_id, pt.performed_at, pt.accounted_at, performed_by, effective_on, Constants::Transaction::LOAN_FEE_RECEIPT)
            end
            Comment.save_comment(remarks, reason_id, 'Lending', lending_id, recorded_by)
            @message[:notice] = "Succesfully preclosed"
          end
        rescue => ex
          @message[:error] << ex.message
        end
      end
    end
    @message[:error].blank? ? @message.delete(:error) : @message.delete(:notice)
    redirect resource(:lendings, :bulk_lending_preclose, :date => effective_on, :parent_location_id => parent_location_id, :child_location_id => child_location_id), :message => @message
  end
  
  def record_lending_preclose
    # INITIALIZATIONS
    @errors  = []
    @lending = Lending.get params[:loan_id]

    # GATE-KEEPING
    receipt_type                    = params[:receipt_type]
    receipt_no                      = params[:receipt_no]
    payment_towards                 = params[:payment_towards]
    on_product_type                 = params[:on_product_type]
    on_product_id                   = params[:on_product_id]
    by_counterparty_type            = params[:by_counterparty_type]
    by_counterparty_id              = params[:by_counterparty_id]
    performed_at                    = params[:performed_at]
    accounted_at                    = params[:accounted_at]
    performed_by                    = params[:performed_by]
    effective_on                    = params[:effective_on]
    product_action                  = params[:product_action]
    reason_id                       = params[:reason]
    remarks                         = params[:remarks]
    recorded_by                     = session.user.id
    make_specific_allocation        = true
    specific_principal_amount       = params[:specific_principal_amount]
    specific_principal_money_amount = MoneyManager.get_money_instance(specific_principal_amount)
    specific_interest_amount        = params[:specific_interest_amount]
    specific_interest_money_amount  = MoneyManager.get_money_instance(specific_interest_amount)
    total_money_amount              = specific_principal_money_amount + specific_interest_money_amount
    fee_amount                      = params[:penalty_amount]
    fee_money_amount                = MoneyManager.get_money_instance(fee_amount)
    fee_product                     = @lending.get_preclosure_penalty_product
    fee_amount                      = fee_product.blank? ? MoneyManager.default_zero_money : fee_product.effective_total_amount

    # VALIDATIONS
    @errors << "Preclosure date must not be future date" if Date.parse(effective_on) > Date.today
    @errors << "Please select Reason" if reason_id.blank?
    @errors << 'Remarks cannot be blank' if remarks.blank?
    @errors << "Penalty Amount is not greater than #{fee_amount}" if fee_money_amount > fee_amount

    # OPERATIONS
    if @errors.blank?
      begin
        
        loan_facade.adjust_advance_for_perclose(effective_on, @lending.id) if @lending.current_advance_available > MoneyManager.default_zero_money
        if total_money_amount > MoneyManager.default_zero_money
          payment_facade.record_payment(total_money_amount, receipt_type.to_sym, payment_towards.to_sym, receipt_no, on_product_type, on_product_id, by_counterparty_type, by_counterparty_id, performed_at, accounted_at, performed_by, effective_on, product_action.to_sym, make_specific_allocation, specific_principal_money_amount, specific_interest_money_amount)
        end
        unless fee_product.blank?
          payment_facade.record_fee_payment(fee_product.id, fee_money_amount, 'receipt', Constants::Transaction::PAYMENT_TOWARDS_FEE_RECEIPT, '','lending', @lending.id, 'client', @lending.loan_borrower.counterparty_id, @lending.administered_at_origin, @lending.accounted_at_origin, performed_by, effective_on, Constants::Transaction::LOAN_FEE_RECEIPT)
        end
        Comment.save_comment(remarks, reason_id, 'Lending', @lending.id, recorded_by)
        message = {:notice => "Succesfully preclosed"}
      rescue => ex
        message = {:error => ex.message}
      end
      redirect url("lendings/#{@lending.id}"), :message => message
    else
      redirect url(:controller => 'lendings', :action => 'check_preclosure_date', :loan_id => @lending.id, :effective_on => effective_on), :message => {:error => @errors.flatten.join('<br>')}
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

  def write_off_lendings
    @lendings = []
    accounted_at    = params[:parent_location_id]
    administered_at = params[:child_location_id]
    on_days         = params[:on_days].blank? ? configuration_facade.days_past_due_eligible_for_writeoff : params[:on_days]
    unless accounted_at.blank?
      @write_off = reporting_facade.loans_eligible_for_write_off(on_days.to_i, accounted_at, administered_at)
      @lendings  = @write_off.last
      @due_days  = @write_off.first
      @location  = administered_at.blank? ? BizLocation.get(accounted_at) : BizLocation.get(administered_at)
      @write_off_lendings = loan_facade.get_loans_at_location(@location, get_effective_date).select{|l| l.is_written_off?}
    end
    display @lendings
  end

  def approve_write_off_lendings
    @message           = {}
    lendings           = []
    @staff_id          = session.user.staff_member.id
    lending_params     = params[:write_off_lendings].blank? ? [] : params[:write_off_lendings]
    parent_location_id = params[:parent_location_id]
    child_location_id  = params[:child_location_id]
    begin
      lending_params.each do |key, value|
        if value.size == 2
          lending  = Lending.get key.to_i
          on_date  = Date.parse(value.last[:on_date])
          lendings << {:lending => lending, :on_date => on_date}
        end
      end
      @message = {:error => "Please select Loan for write off approve"} if lendings.blank?
      if @message[:error].blank?
        lendings.each do |lending_obj|
          lending_obj[:lending].update(:write_off_approve_on_date => lending_obj[:on_date], :write_off_approve => true)
        end
        @message = {:notice => "Loan Write Off approved successfully."}
      end
    rescue => ex
      @message = {:error => "An error has occured: #{ex.message}"}
    end
    redirect resource(:lendings, :write_off_lendings, :on_days => params[:on_days], :parent_location_id => parent_location_id, :child_location_id => child_location_id), :message => @message
  end

  def update_write_off_lendings
    @message           = {}
    lendings           = []
    @staff_id          = session.user.staff_member.id
    lending_params     = params[:write_off_lendings].blank? ? [] : params[:write_off_lendings]
    parent_location_id = params[:parent_location_id]
    child_location_id  = params[:child_location_id]
    begin
      lending_params.each do |key, value|
        if value.size == 2
          lending  = Lending.get key.to_i
          on_date  = Date.parse(value.last[:on_date])
          lendings << {:lending => lending, :on_date => on_date}
        end
      end
      @message = {:error => "Please select Loan for write off"} if lendings.blank?
      if @message[:error].blank?
        lendings.each do |lending_obj|
          lending_obj[:lending].write_off(lending_obj[:on_date], @staff_id)
        end
        @message = {:notice => "Loan Write Off done successfully."}
      end
    rescue => ex
      @message = {:error => "An error has occured: #{ex.message}"}
    end
    redirect resource(:lendings, :write_off_lendings, :on_days => params[:on_days], :parent_location_id => parent_location_id, :child_location_id => child_location_id), :message => @message
  end

  def reschedule_loan_installment
    @lending = Lending.get(params[:id])
    display @lending, :layout => layout?
  end

  def save_reschedule_loan_installment
    #INITIALIZING VARIABLES USED THOURGHTOUT
    @message = {:error => [], :notice => []}

    #GET-KEEPING
    lending_id     = params[:id]
    effective_date = params[:effective_date]
    first_date     = params[:reschedule_first_date]
    staff_id       = params[:staff_id]

    # VALIDATIONS
    @message[:error] << "Loan Id cannot blank" if lending_id.blank?
    @message[:error] << "Effective Date cannot blank" if effective_date.blank?
    @message[:error] << "Re-Schedule First Date cannot be blank" if first_date.blank?
    @lending = Lending.get(lending_id)

    if @message[:error].blank?
      begin
        first_date     = Date.parse(first_date)
        effective_date = Date.parse(effective_date)
        @lending.reschedule_installments(first_date, effective_date)
      rescue => ex
        @message[:error] = "An error has occured :- #{ex.message}"
      end
    end
    @message = {:notice => "Loan Repayment Schedule Dates updated successfully."} if @message[:error].blank?
    @message[:error].blank? ? @message.delete(:error) : @message.delete(:notice)
    redirect request.referer, :message => @message
  end

  private

  def get_all_loans_eligible_for_sec_or_encum(params)
    @lendings = loan_facade.loans_eligible_for_sec_or_encum(params[:child_location_id])
  end

end
