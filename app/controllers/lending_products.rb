class LendingProducts < Application

  def index
    @lending_products = LendingProduct.all
    render
  end

  def new
    @lending_product = LendingProduct.new
    display @lending_product
  end

  def create
    # INITIALIZING VARIABLES USED THROUGHTOUT
    @errors = []
    # GATE-KEEPING
    facade = LoanFacade.new(session.user)
    # VALIDATIONS
    @errors << "Name cannot be blank" if params[:lending_product][:name].blank?
    @errors << "Name cannot be blank" if params[:lending_product][:amount].blank?
    @errors << "Repayment frequency cannot be blank" if params[:lending_product][:repayment_frequency].blank?
    @errors << "Tenure cannot be blank" if params[:lending_product][:tenure].blank?
    @errors << "Interest rate cannot be blank" if params[:lending_product][:interest_rate].blank?
    # OPERATION-PERFORMED
    if @errors.empty?
      @lending_product = LendingProduct.new(params[:lending_product])
      if @lending_product.save
        redirect resource(:lending_products)
      else
        render :new
      end
    else
      render :new
    end
  end
  
end
