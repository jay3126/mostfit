class LoanApplications < Application
  # provides :xml, :yaml, :js

  def bulk_new
    if request.method == :post
      @errors = {}
      @loan_applications = []
      @center = Center.get(params[:at_center_id].to_i)
      @clients = @center.clients if @center
      client_ids = params[:clients].keys
      client_ids.each do |client_id|
        client = Client.get(client_id)
        hash = client.to_loan_application + {
          :amount              => params[:clients][client_id][:amount],
          :created_by_staff_id => params[:staff_member_id].to_i,
          :at_branch_id        => params[:at_branch_id].to_i,
          :at_center_id        => params[:at_center_id].to_i,
          :created_by_user_id  => session.user.id
        }
        loan_application = LoanApplication.new(hash) if params[:clients][client_id][:selected] == "on"
        save_status = loan_application.save if loan_application
        @loan_applications << loan_application if loan_application
        @errors[loan_application.client_id] = loan_application.errors if (save_status == false)
      end
      render 
    else
      @errors = {}
      render
    end
  end

  def list
    if params[:branch_id] == ""
      @errors = "Please select a branch" 
    elsif params[:center_id] == ""
      @errors = "Please select a center"
    else
      @errors = nil
    end
    @center = Center.get(params[:center_id].to_i)
    @clients = @center.clients if @center
    @loan_applications = LoanApplication.all(:at_center_id => @center.id) if @center
    render :bulk_new
  end

  def index
    @errors = {}
    @loan_applications = LoanApplication.all(:order => [:created_at.desc])
    display @loan_applications
  end

end # LoanApplications
