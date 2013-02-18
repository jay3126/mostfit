class LendingProducts < Application

  def index
    @client = Client.get params[:client_id]
    
    @lending_products = LendingProduct.all
    if @lending_products.blank?
      redirect resource(:lending_products, :new)
    else
      display @lending_products
    end
  end

  def new
    @location = BizLocation.get(params[:biz_location_id]) unless params[:biz_location_id].blank?
    @locations = location_facade.all_nominal_branches
    @lending_product = LendingProduct.new
    display @lending_product
  end

  def create
    # INITIALIZING VARIABLES USED THROUGHTOUT
    @message = {}

    # GATE-KEEPING
    name                 = params[:lending_product][:name]
    amount               = params[:lending_product][:amount]
    lp_prefix            = params[:loan_product_prefix]
    lp_identifier        = params[:lending_product][:loan_product_identifier]
    repayment_frequency  = params[:lending_product][:repayment_frequency]
    tenure               = params[:lending_product][:tenure]
    interest_rate        = params[:lending_product][:interest_rate]
    repayment_allocation = params[:lending_product][:repayment_allocation_strategy]
    location_ids         = params[:location_ids]||[]
    insurance_product_id = params[:insurance_product_id]
    fee_product_ids      = params[:fee_product_ids].blank? ? [] : params[:fee_product_ids]
    penalty_fee_ids      = params[:loan_preclosure_penalty_ids].blank? ? [] : params[:loan_preclosure_penalty_ids]
    interest_amount      = params[:lending_product_template][:interest_amount]
    principal_schedule   = params[:lending_product_template][:principal_schedule]
    interest_schedule    = params[:lending_product_template][:interest_schedule]
    user_id              = session.user.id
    staff_id             = session.user.staff_member.id
    @lending_product     = LendingProduct.new(params[:lending_product])

    # VALIDATIONS
    @message[:error] = "Name cannot be blank" if name.blank?
    @message[:error] = "Loan product identifer must not be blank" if lp_identifier.blank?
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
        loan_product_identifier         = lp_prefix + lp_identifier
        money_amount                    = MoneyManager.get_money_instance(amount)
        money_interest_amount           = MoneyManager.get_money_instance(interest_amount)
        money_principal_schedule_amount = MoneyManager.get_money_instance(*principal_schedule.split(','))
        money_interest_schedule_amount  = MoneyManager.get_money_instance(*interest_schedule.split(','))
        fee_product_ids                 = fee_product_ids + penalty_fee_ids unless penalty_fee_ids.blank?
        insurance_product               = SimpleInsuranceProduct.get insurance_product_id unless insurance_product_id.blank?
        lending_product                 = LendingProduct.create_lending_product(name, loan_product_identifier, money_amount, money_interest_amount, interest_rate.to_f, repayment_frequency, tenure.to_i, repayment_allocation, money_principal_schedule_amount, money_interest_schedule_amount, user_id, staff_id, fee_product_ids, insurance_product)

        if lending_product.new?
          @message[:error] = lending_product.error.first.join(', ')
        else
          location_ids.each do |location_id|
            lending_product.lending_product_locations.first_or_create(:biz_location_id => location_id, :effective_on => get_effective_date, :performed_by => staff_id, :recorded_by => user_id )
          end
          @message[:notice] = "Loan Product: '#{@lending_product.name} (Id: #{@lending_product.id})' created successfully"
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
