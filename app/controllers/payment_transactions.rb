class PaymentTransactions < Application

  @@biz_location_ids = []

  def index
    if params[:staff_member_id].blank?
      redirect request.referer
    else
      redirect resource(:payment_transactions, :payment_by_staff_member, params.except(:action, :controller))
    end
  end

  def new
    @payment_transaction = PaymentTransaction.new
    display @payment_transaction
  end

  def payment_form_for_lending
    @lending = Lending.get params[:lending_id]
    @payment_transaction = PaymentTransaction.new
    render :template => 'payment_transactions/payment_form_for_lending', :layout => layout?
  end

  def weeksheet_payments
    @date                = params[:date].blank? ? session[:effective_date] : Date.parse(params[:date])
    @biz_location        = BizLocation.get params[:biz_location_id]
    @parent_biz_location = LocationLink.get_parent(@biz_location, @date)
    @user                = session.user
    @staff_member        = @user.staff_member
    @weeksheet           = CollectionsFacade.new(session.user.id).get_collection_sheet_for_location(@biz_location.id, @date)
    partial 'payment_transactions/weeksheet_payments', :layout => layout?
  end

  def payment_by_staff_member_for_location
    @weeksheets      = []
    @message         = {}
    @message[:error] = 'Staff Member cannot be blank' if params[:staff_member_id].blank?
    @message[:error] = 'Please Select Location For Payment' if @@biz_location_ids.blank? && params[:biz_location_ids].blank?
    if @message[:error].blank?
      @date             = params[:date].blank? ? session[:effective_date] : Date.parse(params[:date])
      @staff_member     = StaffMember.get(params[:staff_member_id])
      @user             = session.user
      @biz_location_ids = params[:biz_location_ids].blank? ? @@biz_location_ids : params[:biz_location_ids]
      @biz_location_ids.each{|location_id| @weeksheets << CollectionsFacade.new(session.user.id).get_collection_sheet(location_id, @date)}
    end
    if @message[:error].blank?
      display @weeksheets.flatten!
    else
      redirect request.referer, :message => @message
    end
  end

  def payment_by_staff_member
    @weeksheets      = []
    @message         = {}
    page             = params[:page].blank? ? 1 : params[:page]
    limit            = 10
    @message[:error] = 'Staff Member cannot be blank' if params[:staff_member_id].blank?
    if @message[:error].blank?
      @date                = params[:date].blank? ? get_effective_date : Date.parse(params[:date])
      @child_biz_location  = BizLocation.get(params[:child_location_id])
      @parent_biz_location = BizLocation.get(params[:parent_location_id])
      @staff_member        = StaffMember.get(params[:staff_member_id])
      @user                = session.user
      @biz_locations, @weeksheets = collections_facade.get_all_collection_sheet_for_staff(@staff_member.id, @date, @parent_biz_location, page, limit)
    end
    @weeksheets = @weeksheets.class == Array ? @weeksheets : [@weeksheets]
    display @weeksheets
  end

  def create_group_payments
    
    # INITIALIZING VARIABLES USED THROUGHTOUT
    @message              = {:error => [], :notice => [],:weeksheet_error => ''}
    @payment_transactions = []
    @client_attendance    = {}
    
    # GATE-KEEPING
    currency     = 'INR'
    receipt      = 'receipt'
    product_type = 'lending'
    cp_type      = 'client'
    recorded_by  = session.user.id
    operation    = params[:operation]
    effective_on = params[:payment_transactions][:on_date]
    payments     = params[:payment_transactions][:payments]
    performed_by = params[:payment_transactions][:performed_by]


    # VALIDATIONS
    @message[:error] << "Date cannot be blank" if effective_on.blank?
    @message[:error] << "Please Select Operation Type(Payment/Attendance/Both)" if operation.blank?
    @message[:error] << "Performed by must not be blank" if performed_by.blank?
    @message[:error] << "Please Select Check box For #{operation.humanize}" if payments.values.select{|f| f[:payment]}.blank?
    
    # OPERATIONS PERFORMED
    if @message[:error].blank?
      payments.values.select{|d| d[:payment]}.each do |payment_value|
        unless payment_value[:payment].blank?

          lending = Lending.get(payment_value[:product_id])
          if lending.is_written_off?
            payment_towards  = Constants::Transaction::PAYMENT_TOWARDS_LOAN_RECOVERY
          else
            payment_towards  = Constants::Transaction::PAYMENT_TOWARDS_LOAN_REPAYMENT
          end
          money_amount    = MoneyManager.get_money_instance(payment_value[:amount].to_f)
          cp_id           = payment_value[:counterparty_id]
          product_id      = payment_value[:product_id]
          performed_at    = payment_value[:performed_at]
          accounted_at    = payment_value[:accounted_at]
          receipt_no      = payment_value[:receipt_no].blank? ? nil : payment_value[:receipt_no]
          if ['client_attendance','payment_and_client_attendance'].include?(operation)
            @client_attendance[cp_id]                     = {}
            @client_attendance[cp_id][:counterparty_type] = 'client'
            @client_attendance[cp_id][:counterparty_id]   = cp_id
            @client_attendance[cp_id][:on_date]           = effective_on
            @client_attendance[cp_id][:at_location]       = performed_at
            @client_attendance[cp_id][:performed_by]      = performed_by
            @client_attendance[cp_id][:recorded_by]       = recorded_by
            @client_attendance[cp_id][:attendance]        = payment_value[:client_attendance]
          end
          if(money_amount.amount > 0 && ['payment','payment_and_client_attendance'].include?(operation))
            payment_transaction     = PaymentTransaction.new(:amount => money_amount.amount, :currency => currency, :effective_on => effective_on,
              :on_product_type      => product_type, :on_product_id  => product_id, :receipt_no => receipt_no,
              :performed_at         => performed_at, :accounted_at   => accounted_at,
              :performed_by         => performed_by, :recorded_by    => recorded_by,
              :by_counterparty_type => cp_type, :by_counterparty_id  => cp_id,
              :receipt_type         => receipt, :payment_towards     => payment_towards)
            if payment_transaction.valid?
              if lending.is_payment_permitted?(payment_transaction)
                @payment_transactions << payment_transaction
              else
                @message[:error] << "#{product_type}(#{product_id}) : {#{payment_transaction.errors.collect{|error| error}.flatten.join(', ')}}"
              end
            else
              @message[:error] << "#{product_type}(#{product_id}) : {#{payment_transaction.errors.collect{|error| error}.flatten.join(', ')}}"
            end
          end
        end
      end
      if @message[:error].blank?
        payments  = {}
        @payment_transactions.each do |pt|
          if pt.save
            payments[pt] = payment_facade.record_payment_allocation(pt)
            @message[:notice] << "#{operation.humanize} successfully created" if @message[:notice].blank?
          else
            @message[:error] << "An error has occured for #{Loan}(#{pt.on_product_id}) : #{pt.errors.first.join(',')}"
          end
        end

        if ['client_attendance','payment_and_client_attendance'].include?(operation)
          Thread.new{
            AttendanceRecord.save_and_update(@client_attendance) if @client_attendance.size > 0
          }
          @message[:notice] << "#{operation.humanize} successfully created" if @message[:notice].blank?
        end
        Thread.new{
          payments.each do |payment, allocation|
            payment_facade.record_payment_accounting(payment, allocation)
          end
        }
      end
    end
    @message[:error].blank? ? @message.delete(:error) : @message.delete(:notice)
    @staff_member_id     = params[:staff_member_id]
    @parent_location_id  = params[:parent_location_id]
    @child_location_id   = params[:child_location_id]
    params[:page]       = params[:page].blank? ? 1 : params[:page]
    page                 = @message[:error].blank? ? params[:page].to_i+1 : params[:page]
    @message[:notice].uniq! unless @message[:notice].blank?
    @message[:error].uniq! unless @message[:error].blank?
    @@biz_location_ids = payments.values.collect{|s| s[:performed_at]}.compact.uniq
    # REDIRECT/RENDER
    if !params[:payment_by].blank? && params[:payment_by] == 'payment_by_staff_member_ro'
      redirect resource(:payment_transactions, :payment_by_staff_member, :date => effective_on, :staff_member_id => params[:staff_member_id], :parent_location_id => params[:parent_location_id], :child_location_id => params[:child_location_id], :page => page, :save_payment => true), :message => @message
    else
      redirect request.referer, :message => @message
    end
  end

  def payment_transactions_on_date
    @branch_id = params[:parent_location_id]
    @center_id = params[:child_location_id]
    @on_date   = params[:date]
    @error = []
    @error << "Please Select Branch" if @branch_id.blank?
    @error << "Please Select Center" if @center_id.blank?
    @error << "Date cannot be blank" if @on_date.blank?
    @payment_transactions = []
    if @error.blank?
      @payment_transactions = PaymentTransaction.all(:accounted_at => @branch_id, :performed_at => @center_id, :effective_on => @on_date, :payment_towards => Constants::Transaction::REVERT_PAYMENT_TOWARDS)
    end
    display @payment_transactions, :message => {:error => @error}
  end

  def destroy_payment_transactions_on_date
    @branch_id = params[:parent_location_id]
    @center_id = params[:child_location_id]
    @on_date   = params[:date]
    @error = []
    @error << "Please Select Branch" if @branch_id.blank?
    @error << "Please Select Center" if @center_id.blank?
    @error << "Date cannot be blank" if @on_date.blank?
    @payment_transactions = []
    if @error.blank?
      @payment_transactions = PaymentTransaction.with_deleted{PaymentTransaction.all(:deleted_at.not => nil, :accounted_at => @branch_id, :performed_at => @center_id, :effective_on => @on_date)}
    end
    render :template => 'payment_transactions/destroy_payment_transactions_on_date', :layout => layout?
  end

  def destroy_payment_transactions
    @error = []
    payments = params[:payment_trasactions]
    @error << "Please Select Check box" if payments.blank?
    if @error.blank?
      payments.each do |payment_id|
        payment = PaymentTransaction.get payment_id
        payment.delete_payment_transaction
      end
    end

    if @error.blank?
      redirect request.referer, :message => {:notice => "Payment Transaction successfully deleted"}
    else
      redirect request.referer, :message => {:error => @error}
    end
  end

  def payment_by_branch
    @locations = BizLocation.all('location_level.level' => 1)
    @date = params[:date]||get_effective_date
    @date = Date.parse(@date) if @date.class != Date
    @loans_status = {}
    all_loan_ids = Lending.all('loan_base_schedule.base_schedule_line_items.on_date' => @date).aggregate(:id) rescue []
    all_loan_receipts = all_loan_ids.blank? ? [] : LoanReceipt.all(:lending_id => all_loan_ids, :effective_on.lte => @date)
    all_loan_schedules = all_loan_ids.blank? ? [] : BaseScheduleLineItem.all('loan_base_schedule.lending_id' => all_loan_ids, :on_date => @date)
    @locations.each do |location|
      loan_ids = LoanAdministration.get_loan_ids_accounted_by_sql(location.id, @date, false, 'disbursed_loan_status')

      loans = all_loan_ids & loan_ids
      @loans_status[location.id] = {}
      schedules = loans.blank? ? [] : all_loan_schedules.select{|s| loans.include?(s.loan_base_schedule.lending_id)}
      scheduled_principal = schedules.blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance_least_terms(schedules.map(&:scheduled_principal_due).sum.to_i)
      scheduled_interest = schedules.blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance_least_terms(schedules.map(&:scheduled_interest_due).sum.to_i)
      loan_receipts = loans.blank? ? [] : all_loan_receipts.select{|s| loans.include?(s.lending_id) and s.effective_on <= @date}
      loan_amounts = LoanReceipt.add_up(loan_receipts)
      advance = loan_amounts[:advance_received] > loan_amounts[:advance_adjusted] ? loan_amounts[:advance_received] - loan_amounts[:advance_adjusted] : MoneyManager.default_zero_money
      loan_receipts_on_date = loan_receipts.blank? ? [] : loan_receipts.select{|s| s.effective_on == @date}
      loan_amounts_on_date = LoanReceipt.add_up(loan_receipts_on_date)
      principal_received = loan_amounts_on_date[:principal_received]
      interest_received = loan_amounts_on_date[:interest_received]
      @loans_status[location.id] = {:location_name => location.name, :scheduled_principal => scheduled_principal, :scheduled_interest => scheduled_interest, :advance_balance => advance, :principal_recevied => principal_received, :interest_received => interest_received}
    end
    display @locations
  end

end