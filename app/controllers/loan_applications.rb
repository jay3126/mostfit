class LoanApplications < Application
  # provides :xml, :yaml, :js

  def bulk_new
    if request.method == :post
      @errors = {}
      @center = Center.get(params[:at_center_id].to_i)    
      center_cycle = CenterCycle.get_cycle(@center.id, params[:center_cycle_number].to_i)
      client_ids_from_center = @center.clients.aggregate(:id) if @center
      client_ids_from_existing_loan_applications = LoanApplication.all(:at_center_id => @center.id, :center_cycle_id => center_cycle.id).aggregate(:client_id)
      final_client_ids = client_ids_from_center - client_ids_from_existing_loan_applications
      @clients = Client.all(:id => final_client_ids, :order => [:name.asc])
      client_ids = params[:clients].keys
      if params[:staff_member_id].empty? or params[:created_on].empty?
        @errors = []
        @errors << "Please select a Staff Member" if params[:staff_member_id].empty?
        @errors << "Please select a created on date" if params[:created_on].empty?
      else 
        client_ids.each do |client_id|
          client = Client.get(client_id)
          hash = client.to_loan_application + {
            :amount              => params[:clients][client_id][:amount],
            :created_by_staff_id => params[:staff_member_id].to_i,
            :at_branch_id        => params[:at_branch_id].to_i,
            :at_center_id        => params[:at_center_id].to_i,
            :created_by_user_id  => session.user.id,
            :center_cycle_id     => center_cycle.id,
            :created_on          => created_on
          }
          loan_application = LoanApplication.new(hash) if params[:clients][client_id][:selected] == "on"
          save_status = loan_application.save if loan_application
          @errors[loan_application.client_id] = loan_application.errors if (save_status == false)
        end
      end
      @loan_applications = LoanApplication.all(:created_by_user_id => session.user.id, :at_center_id => @center.id, :center_cycle_id => center_cycle.id, :order => [:created_at.desc])
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
    if @center
      center_cycle_number = CenterCycle.get_current_center_cycle(@center.id)
      center_cycle = CenterCycle.get_cycle(@center.id, center_cycle_number)
      client_ids_from_center = @center.clients.aggregate(:id) 
      client_ids_from_existing_loan_applications = LoanApplication.all(:at_center_id => @center.id, :center_cycle_id => center_cycle.id).aggregate(:client_id)
      final_client_ids = client_ids_from_center - client_ids_from_existing_loan_applications
      @clients = Client.all(:id => final_client_ids, :order => [:name.asc])
      @loan_applications = LoanApplication.all(:at_center_id => @center.id, :center_cycle_id => center_cycle.id, :order => [:created_at.desc])
    end
    render :bulk_new
  end

  def index
    @errors = {}
    @loan_applications = LoanApplication.all(:order => [:created_at.desc])
    display @loan_applications
  end

end # LoanApplications
