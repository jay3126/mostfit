class SimpleInsurancePolicies < Application

  def index
    @policies = SimpleInsurancePolicy.all
    display @policies
  end

  def new
    @policy = SimpleInsurancePolicy.new
    display @policy
  end

  def create
    #INITIALIZING VARIABLES USED THOURGHTOUT
    @message = {}

    #GET-KEEPING
    insura_product_id  = params[:simple_insurance_product_id]
    client_id          = params[:client_id]
    insured_name       = params[:simple_insurance_policy][:insured_name]
    insured_type       = params[:simple_insurance_policy][:insured_type]
    insurance_for      = params[:simple_insurance_policy][:insurance_for]
    proposed_on        = params[:simple_insurance_policy][:proposed_on]
    insured_on         = params[:simple_insurance_policy][:insured_on]
    insured_amount     = params[:simple_insurance_policy][:insured_amount]
    currency           = params[:simple_insurance_policy][:currency]
    expires_on         = params[:simple_insurance_policy][:expires_on]
    issued_status      = params[:simple_insurance_policy][:issued_status]

    # VALIDATIONS
    @message[:error] = "Insurance Name cannot blank" if insured_name.blank?
    @message[:error] = "Insureance Type cannot blank" if insured_type.blank?
    @message[:error] = "Please select Insurance For" if insurance_for.blank?
    @message[:error] = "Proposed On cannot blank" if proposed_on.blank?
    @message[:error] = "Insurance On cannot blank" if insured_on.blank?
    @message[:error] = "Insurance Amount cannot blank" if insured_amount.blank?
    @message[:error] = "Expires On cannot blank" if expires_on.blank?
    @message[:error] = "Issued Status cannot blank" if issued_status.blank?
    @message[:error] = "Currency cannot blank" if currency.blank?
    @policy = SimpleInsurancePolicy.new(params[:simple_insurance_policy])

    # PERFORM OPERATION
    if @message[:error].blank?
      begin
        amt = MoneyManager.get_money_instance(insured_amount)
        insur_policy = SimpleInsurancePolicy.new(:insured_name => insured_name, :insured_type => insured_type, :insurance_for => insurance_for, :proposed_on => proposed_on,
          :insured_on => insured_on, :insured_amount => amt.amount, :expires_on => expires_on, :issued_status => issued_status, :currency => currency,
          :client_id => client_id, :simple_insurance_product_id => insura_product_id)
        if insur_policy.save
          @message[:notice] = "Insurance Policy created successfully"
        else
          @message[:error] = insur_policy.errors.first.join(", ")
        end
      rescue => ex
        @message = {:error => "An error has occured: #{ex.message}"}
      end
    end

    #REDIRECTION/RENDER
    if @message[:error].blank?
      redirect resource(:simple_insurance_policies), :message => @message
    else
      render :new
    end

  end

  def edit
    @policy = SimpleInsurancePolicy.get params[:id]
    display @policy
  end

  def update
    #INITIALIZING VARIABLES USED THOURGHTOUT
    @message = {}

    #GET-KEEPING
    insured_name       = params[:simple_insurance_policy][:insured_name]
    insured_on         = params[:simple_insurance_policy][:insured_on]
    issued_status     = params[:simple_insurance_policy][:issued_status]
    expires_on         = params[:simple_insurance_policy][:expires_on]

    # VALIDATIONS
    @message[:error] = "Insurance Name cannot blank" if insured_name.blank?
    @message[:error] = "Insured On cannot blank" if insured_on.blank?
    @message[:error] = "Issued Status cannot blank" if issued_status.blank?
    @message[:error] = "Expires On cannot blank" if expires_on.blank?
    @policy = SimpleInsurancePolicy.get(params[:id])

    # PERFORM OPERATION
    if @message[:error].blank?
      begin
        @policy.attributes = {:insured_name => insured_name, :insured_on => insured_on, :issued_status => issued_status, :expires_on => expires_on}
        if @policy.save
          @message[:notice] = "Insurance Policy created successfully"
        else
          @message[:error] = @policy.errors.first.join(", ")
        end
      rescue => ex
        @message = {:error => "An error has occured: #{ex.message}"}
      end
    end

    #REDIRECTION/RENDER
    if @message[:error].blank?
      redirect resource(:simple_insurance_policies), :message => @message
    else
      render :edit
    end
  end

  def show
    @policy = SimpleInsurancePolicy.get params[:id]
    display @policy
  end
end
