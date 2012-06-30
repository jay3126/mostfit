class SimpleFeeProducts < Application

  def index
    @fee_products = SimpleFeeProduct.all
    @fee_product = SimpleFeeProduct.new
    display @fee_products
  end

  def create
    #VARIABLES THAT IS USED THROUGHTOUT
    @message = {}

    #GET-KEEPING
    name            = params[:simple_fee_product][:name]
    fee_charge_type = params[:simple_fee_product][:fee_charged_on_type]
    created_on      = params[:simple_fee_product][:created_on]

    #VALIDATION
    @message[:error] = 'Created On cannot be blank' if created_on.blank?
    @message[:error] = 'Fee Charge Type cannot be blank' if fee_charge_type.blank?
    @message[:error] = 'Name cannot be blank' if name.blank?

    #PERFORM OPERTION
    begin
      if @message[:error].blank?
        fee = SimpleFeeProduct.new(:name => name, :fee_charged_on_type => fee_charge_type, :created_on => created_on)
        if fee.save
          @message[:notice] = 'Fee Product saved successfully'
        else
          @message[:error] = 'Fee Product saved fail'
        end
      end
    rescue => ex
      @message = {:error => "An error has occured: #{ex.message}"}
    end

    #REDIREATION/RENDER
    redirect resource(:simple_fee_products), :message => @message

  end

  def show
    @fee_product = SimpleFeeProduct.get params[:id]
    @fee_timed_amounts = @fee_product.timed_amounts
    @timed_amount  = TimedAmount.new
    display @fee_product
  end

  def fee_timed_amount_create
    #VARIABLES THAT IS USED THROUGHTOUT
    @message = {}

    #GET-KEEPING
    fee_product_id = params[:id]
    fee_amount     = params[:timed_amount][:fee_only_amount]
    tax_amount     = params[:timed_amount][:tax_only_amount]
    currency       = params[:timed_amount][:currency]
    effective_on   = params[:timed_amount][:effective_on]
    fee_product    = SimpleFeeProduct.get fee_product_id

    #VALIDATION
    @message[:error] = 'Effective On cannot be blank' if effective_on.blank?
    @message[:error] = 'Currency cannot be blank' if currency.blank?
    @message[:error] = 'Tax amount cannot be blank' if tax_amount.blank?
    @message[:error] = 'Fee amount cannot be blank' if fee_amount.blank?

    #PERFORM OPERTION
    begin
      if @message[:error].blank?
        fee_money_amount = MoneyManager.get_money_instance(fee_amount)
        tax_money_amount = MoneyManager.get_money_instance(tax_amount)
        fee_time_amount = fee_product.timed_amounts.new(:fee_only_amount => fee_money_amount.amount, :tax_only_amount => tax_money_amount.amount , :currency => currency, :effective_on => effective_on)
        if fee_time_amount.save
          @message[:notice] = 'Fee Time Amount saved successfully'
        else
          @message[:error] = 'Fee Time Amount saved fail'
        end
      end
    rescue => ex
      @message = {:error => "An error has occured: #{ex.message}"}
    end

    #REDIREATION/RENDER
    redirect resource(fee_product), :message => @message

  end

end