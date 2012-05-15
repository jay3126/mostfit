class PaymentTransactions < Application

  def index
    @payment_transactions = PaymentTransaction.all
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
      redirect resource(:payment_transactions), :message => @message
    else
      render :new
    end

  end
end