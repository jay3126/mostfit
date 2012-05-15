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

    @message[:error] = "Please select Location Level !" if amount.blank?
    @message[:error] = "Name cannot be blank !" if product_id.blank?

    # OPERATIONS PERFORMED
    if @message[:error].blank?
      begin
        @payment_transaction = PaymentTransaction.new(:amount => amount, :currency => currency, 
          :on_product_type => product_type, :on_product_id => product_id,
          :performed_at => performed_at, :accounted_at => accounted_at,
          :performed_by => performed_by, :recorded_by => recorded_by,
          :by_counterparty_type => cp_type, :by_counterparty_id => cp_id,
          :receipt_type => receipt, :effective_on => effective_on)
        if @payment_transaction.save
          @message = {:notice => " Location successfully created"}
        else
          @message = {:error => @payment_transaction.errors.collect{|error| error}.flatten.join(', ')}
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