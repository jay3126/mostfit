class PaymentTransactions < Application

  def index
    if params[:lending_ids]
      @payment_transactions = PaymentTransaction.all(:on_product_id => params[:lending_ids], :on_product_type => :lending)
    elsif params[:payment_ids]
      @payment_transactions = PaymentTransaction.all(:id => params[:payment_ids])
    else
      @payment_transactions = PaymentTransaction.all
    end
    display @payment_transactions
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
    @date = params[:date].blank? ? session[:effective_date] : Date.parse(params[:date])
    @biz_location = BizLocation.get params[:biz_location_id]
    @parent_biz_location = LocationLink.get_parent(@biz_location, @date)
    @user = session.user
    @weeksheet = CollectionsFacade.new(session.user.id).get_collection_sheet(@biz_location.id, @date)
    display @weeksheet

  end

  def payment_by_staff_member_for_location
    @weeksheets      = []
    @message         = {}
    @message[:error] = 'Staff Member cannot be blank' if params[:staff_member_id].blank?
    @message[:error] = 'Please Select Location For Payment' if params[:biz_location_ids].blank?
    if @message[:error].blank?
      @date             = params[:date].blank? ? session[:effective_date] : Date.parse(params[:date])
      @staff_member     = StaffMember.get(params[:staff_member_id])
      @user             = session.user
      @biz_location_ids = params[:biz_location_ids]
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
    @message[:error] = 'Staff Member cannot be blank' if params[:staff_member_id].blank?
    if @message[:error].blank?
      @date                = params[:date].blank? ? session[:effective_date] : Date.parse(params[:date])
      @child_biz_location  = BizLocation.get params[:child_location_id]
      @parent_biz_location = BizLocation.get params[:parent_location_id]
      @staff_member        = StaffMember.get(params[:staff_member_id])
      @user                = session.user
      @weeksheets          = collections_facade.get_collection_sheet_for_staff(@staff_member.id, @date)
    end
    display @weeksheets.flatten!
  end

  def create_group_payments
    # INITIALIZING VARIABLES USED THROUGHTOUT
    @message = {}
    @payment_transactions = []

    # GATE-KEEPING
    currency     = params[:payment_transactions][:currency]
    receipt      = params[:payment_transactions][:receipt_type]
    performed_at = params[:payment_transactions][:performed_at]
    accounted_at = params[:payment_transactions][:accounted_at]
    performed_by = params[:payment_transactions][:performed_by]
    recorded_by  = params[:payment_transactions][:recorded_by]
    effective_on = params[:payment_transactions][:effective_on]
    payments     = params[:payment_transactions][:payments]

    # VALIDATIONS
    @message[:error] = "Performed by must not be blank" if performed_by.blank?

    # OPERATIONS PERFORMED
    if @message[:error].blank?
      begin
        payments.each do |key, payment_value|
          amount       = payment_value[:amount]
          money_amount = MoneyManager.get_money_instance(amount.to_i)
          payment_towards = Constants::Transaction::PAYMENT_TOWARDS_LOAN_REPAYMENT
          cp_type      = payment_value[:counterparty_type]
          cp_id        = payment_value[:counterparty_id]
          product_type = payment_value[:product_type]
          product_id   = payment_value[:product_id]
          if money_amount.amount > 0
            payment_transaction = PaymentTransaction.new(:amount => money_amount.amount, :currency => currency,
              :on_product_type => product_type, :on_product_id => product_id,
              :performed_at => performed_at, :accounted_at => accounted_at,
              :performed_by => performed_by, :recorded_by => recorded_by,
              :by_counterparty_type => cp_type, :by_counterparty_id => cp_id,
              :receipt_type => receipt, :payment_towards => payment_towards, :effective_on => effective_on)
            if payment_transaction.valid?
              if payment_facade.is_loan_payment_permitted?(payment_transaction)
                @payment_transactions << payment_transaction
              else
                @message[:error]= "#{@message[:error]}  #{product_type}(#{product_id}) {#{payment_transaction.errors.collect{|error| error}.flatten.join(', ')}}"
              end
            end
          end
        end

        if @message[:error].blank?
          @payment_transactions.each do |pt|
            begin
              money_amount = pt.to_money[:amount]
              payment_facade.record_payment(money_amount, pt.receipt_type, pt.payment_towards, pt.on_product_type, pt.on_product_id, pt.by_counterparty_type, pt.by_counterparty_id, pt.performed_at, pt.accounted_at, pt.performed_by, pt.effective_on, Constants::Transaction::LOAN_REPAYMENT)
              @message = {:notice => "Payment successfully created"}
            rescue => ex
              @message = {:error => "An error has occured: #{ex.message}"}
            end
          end
        end

      rescue => ex
        @message = {:error => "An error has occured: #{ex.message}"}
      end
    end

    # REDIRECT/RENDER
    redirect resource(:payment_transactions, :weeksheet_payments, :biz_location_id => performed_at, :date => effective_on), :message => @message
  end
  
end