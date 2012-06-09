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

  def create
    # INITIALIZING VARIABLES USED THROUGHTOUT

    @message = {}
    mf = FacadeFactory.instance.get_instance(FacadeFactory::PAYMENT_FACADE, session.user)


    # GATE-KEEPING

    amount       = params[:payment_transaction][:amount]
    currency     = params[:payment_transaction][:currency]
    receipt      = params[:payment_transaction][:receipt_type]
    product_type = params[:payment_transaction][:on_product_type]
    product_id   = params[:payment_transaction][:on_product_id]
    performed_at = params[:payment_transaction][:performed_at]
    accounted_at = params[:payment_transaction][:accounted_at]
    performed_by = params[:payment_transaction][:performed_by]
    recorded_by  = params[:payment_transaction][:recorded_by]
    cp_type      = params[:payment_transaction][:by_counterparty_type]
    cp_id        = params[:payment_transaction][:by_counterparty_id]
    effective_on = params[:payment_transaction][:effective_on]

    # VALIDATIONS

    #@message[:error] = "Amount cannot be blank" if amount.blank?
    #@message[:error] = "Product cannot be blank" if product_id.blank?

    # OPERATIONS PERFORMED
    if @message[:error].blank?
      begin
        @payment_transaction = PaymentTransaction.new(:amount => amount, :currency => currency,
          :on_product_type => product_type, :on_product_id => product_id,
          :performed_at => performed_at, :accounted_at => accounted_at,
          :performed_by => performed_by, :recorded_by => recorded_by,
          :by_counterparty_type => cp_type, :by_counterparty_id => cp_id,
          :receipt_type => receipt, :effective_on => effective_on)
        money_amount = MoneyManager.get_money_instance_least_terms(amount.to_i)
        @copy_payment_transaction = mf.record_payment(money_amount, receipt, product_type, product_id, cp_type, cp_id, performed_at, accounted_at, performed_by, effective_on, nil)

        if @copy_payment_transaction.saved?
          @message = {:notice => "Payment Transaction successfully created"}
        else
          @message = {:error => @copy_payment_transaction.errors.collect{|error| error}.flatten.join(', ')}
        end
      rescue => ex
        @message = {:error => "An error has occured: #{ex.message}"}
      end
    end
    #REDIRECT/RENDER
    if @message[:error].blank?
      redirect resource(:payment_transactions, :payment_ids => [@copy_payment_transactionons.id]), :message => @message
    else
      render :new
    end

  end

  def weeksheet_payments
    @date = params[:date].blank? ? session[:effective_date] : Date.parse(params[:date])
    @biz_location = BizLocation.get params[:biz_location_id]
    @parent_biz_location = LocationLink.get_parent(@biz_location, @date)
    @user = session.user
    @weeksheet = CollectionsFacade.new(session.user.id).get_collection_sheet(@biz_location.id, @date)

    display @weeksheet

  end

  def create_group_payments
    # INITIALIZING VARIABLES USED THROUGHTOUT

    @message = {}
    @payment_transactions = []
    mf = FacadeFactory.instance.get_instance(FacadeFactory::PAYMENT_FACADE, session.user.id)


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


    # OPERATIONS PERFORMED
    if @message[:error].blank?
      begin
        payments.each do |key, payment_value|
          amount       = payment_value[:amount]
          cp_type      = payment_value[:counterparty_type]
          cp_id        = payment_value[:counterparty_id]
          product_type = payment_value[:product_type]
          product_id   = payment_value[:product_id]
          money_amount = MoneyManager.get_money_instance_least_terms(amount.to_i)
          payment_transaction = PaymentTransaction.new(:amount => money_amount.amount, :currency => currency,
            :on_product_type => product_type, :on_product_id => product_id,
            :performed_at => performed_at, :accounted_at => accounted_at,
            :performed_by => performed_by, :recorded_by => recorded_by,
            :by_counterparty_type => cp_type, :by_counterparty_id => cp_id,
            :receipt_type => receipt, :effective_on => effective_on)
          if payment_transaction.valid?
            @payment_transactions << payment_transaction
          else
            @message[:error]= "#{@message[:error]}  #{product_type}(#{product_id}) {#{payment_transaction.errors.collect{|error| error}.flatten.join(', ')}}"
          end
        end
        @payment_transactions.each do |pt|
          money_amount = MoneyManager.get_money_instance(pt.amount.to_i)
          mf.record_payment(money_amount, pt.receipt_type, pt.on_product_type, pt.on_product_id, pt.by_counterparty_type, pt.by_counterparty_id, pt.performed_at, pt.accounted_at, pt.performed_by, pt.effective_on, Constants::Transaction::LOAN_REPAYMENT)
        end
      rescue => ex
        @message = {:error => "An error has occured: #{ex.message}"}
      end
    end
    #REDIRECT/RENDER
    if @message[:error].blank?
      redirect resource(:payment_transactions, :lending_ids => @payment_transactions.map(&:on_product_id) ), :message => @message
    else
      redirect resource(:payment_transactions, :biz_location_id => performed_at, :date => effective_on)
    end
  end
end