class SimpleInsuranceProducts < Application

  def index
    @insurance_products = SimpleInsuranceProduct.all
    @insurance_product = SimpleInsuranceProduct.new
    @fee_products      = SimpleFeeProduct.all(:fee_charged_on_type => Constants::Transaction::PREMIUM_COLLECTED_ON_INSURANCE)
    display @insurance_products
  end

  def create
    #VARIABLES THAT IS USED THROUGHTOUT
    @message = {}

    #GET-KEEPING
    name          = params[:simple_insurance_product][:name]
    insured_type  = params[:simple_insurance_product][:insured_type]
    insurance_for = params[:simple_insurance_product][:insurance_for]
    created_on    = params[:simple_insurance_product][:created_on]

    #VALIDATION
    @message[:error] = 'Created On cannot be blank' if created_on.blank?
    @message[:error] = 'Fee Charge Type cannot be blank' if insurance_for.blank?
    @message[:error] = 'Name cannot be blank' if name.blank?

    #PERFORM OPERTION
    begin
      if @message[:error].blank?
        insurance = SimpleInsuranceProduct.new(:name => name, :insured_type => insured_type, :insurance_for => insurance_for, :created_on => created_on)
        if insurance.save
          fee = SimpleFeeProduct.get params[:fee_product_id]
          fee.update(:simple_insurance_product_id => insurance.id) unless fee.blank?
          @message[:notice] = 'Insurance Product saved successfully'
        else
          @message[:error] = 'Insurance Product saved fail'
        end
      end
    rescue => ex
      @message = {:error => "An error has occured: #{ex.message}"}
    end

    #REDIREATION/RENDER
    redirect resource(:simple_insurance_products), :message => @message

  end

end