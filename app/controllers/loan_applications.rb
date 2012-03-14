class LoanApplications < Application
  # provides :xml, :yaml, :js

  def bulk_new
    if request.method == :post
      @errors = {}
      client_ids = params[:clients].keys
      client_ids.each do |client_id|
        loan_application = LoanApplication.new(:client_id => client_id, 
                                               :amount => params[:clients][client_id][:amount],
                                               :created_by_staff_id => params[:staff_member_id].to_i,
                                               :created_by_user_id => session.user.id) if params[:clients][client_id][:selected] == "on"
        save_status = loan_application.save if loan_application
        @errors[client_id] = loan_application.errors if (save_status == false)
      end
      render :bulk_new
    else
      @errors = {}
      render
    end
  end

  def list
    @center = Center.get(params[:center_id].to_i)
    raise NotFound unless @center
    @clients = @center.clients
    render :bulk_new
  end

  def index
    @loan_applications = LoanApplication.all
    display @loan_applications
  end

  def show(id)
    @loan_application = LoanApplication.get(id)
    raise NotFound unless @loan_application
    display @loan_application
  end

  def new
    only_provides :html
    @loan_application = LoanApplication.new
    display @loan_application
  end

  # def edit(id)
  #   only_provides :html
  #   @loan_application = LoanApplication.get(id)
  #   raise NotFound unless @loan_application
  #   display @loan_application
  # end

  # def create(loan_application)
  #   @loan_application = LoanApplication.new(loan_application)
  #   if @loan_application.save
  #     redirect resource(@loan_application), :message => {:notice => "LoanApplication was successfully created"}
  #   else
  #     message[:error] = "LoanApplication failed to be created"
  #     render :new
  #   end
  # end

  # def update(id, loan_application)
  #   @loan_application = LoanApplication.get(id)
  #   raise NotFound unless @loan_application
  #   if @loan_application.update(loan_application)
  #      redirect resource(@loan_application)
  #   else
  #     display @loan_application, :edit
  #   end
  # end

  # def destroy(id)
  #   @loan_application = LoanApplication.get(id)
  #   raise NotFound unless @loan_application
  #   if @loan_application.destroy
  #     redirect resource(:loan_applications)
  #   else
  #     raise InternalServerError
  #   end
  # end

end # LoanApplications
