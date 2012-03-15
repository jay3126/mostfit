class LoanApplications < Application
  # provides :xml, :yaml, :js

  def bulk_new
    if request.method == :post
      @errors = {}
      @loan_applications = []
      client_ids = params[:clients].keys
      client_ids.each do |client_id|
        client = Client.get(client_id)
        loan_application = LoanApplication.new(:client_id => client_id, 
                                               :client_name => client.name,
                                               :client_dob => client.date_of_birth,
                                               :client_address => client.address,
                                               :client_reference1 => client.reference,
                                               :amount => params[:clients][client_id][:amount],
                                               :created_by_staff_id => params[:staff_member_id].to_i,
                                               :at_branch_id => params[:at_branch_id].to_i,
                                               :at_center_id => params[:at_center_id].to_i,
                                               :created_by_user_id => session.user.id) if params[:clients][client_id][:selected] == "on"
        save_status = loan_application.save if loan_application
        @loan_applications << loan_application if loan_application
        @errors[client_id] = loan_application.errors if (save_status == false)
      end
      render :index
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
    @loan_applications = LoanApplication.all(:order => [:created_at.desc])
    display @loan_applications
  end

end # LoanApplications
