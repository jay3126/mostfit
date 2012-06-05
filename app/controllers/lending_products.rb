class LendingProducts < Application

  def index
    @client = Client.get params[:client_id]
    @lending_products = LendingProduct.all
    render
  end

  def new
    @lending_product = LendingProduct.new
    display @lending_product
  end

  def create
    # INITIALIZING VARIABLES USED THROUGHTOUT
    @message = {}

    # GATE-KEEPING
    name = params[:lending_product][:name]
    amount = params[:lending_product][:amount]
    repayment_frequency = params[:lending_product][:repayment_frequency]
    tenure = params[:lending_product][:tenure]
    interest_rate = params[:lending_product][:interest_rate]
    repayment_allocation = params[:lending_product][:repayment_allocation_strategy]
    interest_amount = params[:lending_product_template][:interest_amount]
    principal_schedule = params[:lending_product_template][:principal_schedule]
    interest_schedule = params[:lending_product_template][:interest_schedule]
    @lending_product = LendingProduct.new(params[:lending_product])

    # VALIDATIONS
    @message[:error] = "Name cannot be blank" if name.blank?
    @message[:error] = "Name cannot be blank" if amount.blank?
    @message[:error] = "Repayment frequency cannot be blank" if repayment_frequency.blank?
    @message[:error] = "Tenure cannot be blank" if tenure.blank?
    @message[:error] = "Interest rate cannot be blank" if interest_rate.blank?
    @message[:error] = "Please select Repayment Allocation Strategy" if repayment_allocation.blank?
    @message[:error] = "Interest Amount cannot blank" if interest_amount.blank?
    @message[:error] = "Principal Schedule cannot blank" if principal_schedule.blank?
    @message[:error] = "Interest Schedule cannot blank" if interest_schedule.blank?

    # OPERATION-PERFORMED
    if @message[:error].blank?
      begin
        money_amount = Money.new(amount.to_i, :INR)
        money_interest_amount = Money.new(interest_amount.to_i, :INR)
        money_principal_schedule_amount = principal_schedule.split(',').collect{|c| Money.new(c.to_i, :INR)}
        money_interest_schedule_amount = interest_schedule.split(',').collect{|c| Money.new(c.to_i, :INR)}
       lending_product = LendingProduct.create_lending_product(name, money_amount, money_interest_amount, interest_rate.to_f, repayment_frequency, tenure.to_i, repayment_allocation, money_principal_schedule_amount, money_interest_schedule_amount)

        if lending_product.new?
          @message[:error] = lending_product.error.first.join(', ')
        else
          @message[:notice] = "Lending Product creation successfully"
        end
      rescue => ex
        @message[:error] = "An error has occured: #{ex.message}"
      end
    end

    #REDIRECT/RENDER
    if @message[:error].blank?
      redirect resource(:lending_products), :message => @message
    else
      render :new
    end
  end

  def show
    @lending_product = LendingProduct.get params[:id]
    @lendings = @lending_product.lendings
    display @lending_product
  end
  
end
