class ClientVerifications < Application
  # provides :xml, :yaml, :js

  def pending_verifications
    if params['center_id'] and not params['center_id'].empty?
        @center_id = params['center_id'] 
    else
        @center_id = nil
    end
    
    if params['branch_id'] and not params['branch_id'].empty?
        @branch_id = params['branch_id']
    else
        @branch_id = nil
    end
    @recorded = true

    @loan_applications_pending_verification = LoanApplication.pending_verification(@branch_id, @center_id)
    @loan_applications_recently_recorded = LoanApplication.recently_recorded(@branch_id, @center_id)
    render 
  end

  #records the given CPVs 
  def record_verifications
    params['verification_status'].keys.each do | cpv_type |
      puts "Verifying for #{cpv_type}"

      #construct the right method name to call -- record_CPVNUMBER_approve or record_CPVNUMBER_reject
      params['verification_status'][cpv_type].keys.each do | id |
          data = params['verification_status'][cpv_type][id]
          method_name = 'record_' + cpv_type.to_s.split('_')[0];
          
          if data == Constants::Verification::VERIFIED_ACCEPTED
            method_name = method_name + '_approved';
          elsif data == Constants::Verification::VERIFIED_REJECTED
            method_name = method_name + '_rejected'
          end
          puts "Calling #{method_name} on ClientVerification"
          
          #placeholder code -- needs to be refined
          ClientVerification.send(method_name,*[id,2,Date.today(),2])
      end
   end
   
    render
  end

  def index
    render partial "filter_form"
  end

  def show(id)
    @client_verification = ClientVerification.get(id)
    raise NotFound unless @client_verification
    display @client_verification
  end

  def new
    only_provides :html
    @client_verification = ClientVerification.new
    display @client_verification
  end

  def edit(id)
    only_provides :html
    @client_verification = ClientVerification.get(id)
    raise NotFound unless @client_verification
    display @client_verification
  end

  def create(client_verification)
    @client_verification = ClientVerification.new(client_verification)
    if @client_verification.save
      redirect resource(@client_verification), :message => {:notice => "ClientVerification was successfully created"}
    else
      message[:error] = "ClientVerification failed to be created"
      render :new
    end
  end

  def update(id, client_verification)
    @client_verification = ClientVerification.get(id)
    raise NotFound unless @client_verification
    if @client_verification.update(client_verification)
       redirect resource(@client_verification)
    else
      display @client_verification, :edit
    end
  end

  def destroy(id)
    @client_verification = ClientVerification.get(id)
    raise NotFound unless @client_verification
    if @client_verification.destroy
      redirect resource(:client_verifications)
    else
      raise InternalServerError
    end
  end

end # ClientVerifications
