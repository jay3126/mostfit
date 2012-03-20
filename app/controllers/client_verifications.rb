class ClientVerifications < Application
  # provides :xml, :yaml, :js

  #gets data from models using the provided params
  def get_data(params)
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
    @center = Center.get(@center_id)
    @user_id = session.user.id 
    @loan_applications_pending_verification = LoanApplication.pending_verification(@branch_id, @center_id)
    @loan_applications_recently_recorded = LoanApplication.recently_recorded_by_user(@user_id)
  end

  #gives the loan applications pending for verification
  def pending_verifications
    @show_pending = true
    get_data(params)
    render :verifications 
  end

  #records the given CPVs and shows the list of recently recorded AND the other Loan Applications pending verifications
  def record_verifications
    @center = Center.get(@center_id)
    #show the recently recorded verifications
    if params.key?('verification_status')
       params['verification_status'].keys.each do | cpv_type |
          puts "Verifying for #{cpv_type}"
              params['verification_status'][cpv_type].keys.each do | id |
                  verified_by_staff_id = params['verified_by_staff_id'][cpv_type][id]
                  verification_status = params['verification_status'][cpv_type][id]
                  verified_on_date = params['verified_on_date'][cpv_type][id]
                  if cpv_type == Constants::Verification::CPV1
                    if verification_status == Constants::Verification::VERIFIED_ACCEPTED
                        ClientVerification.record_CPV1_approved(id,verified_by_staff_id, verified_on_date, session.user.id)
                    elsif verification_status == Constants::Verification::VERIFIED_REJECTED 
                        ClientVerification.record_CPV1_rejected(id,verified_by_staff_id, verified_on_date, session.user.id)
                    end
                  elsif cpv_type == Constants::Verification::CPV2
                    if verification_status == Constants::Verification::VERIFIED_ACCEPTED 
                        ClientVerification.record_CPV2_approved(id,verified_by_staff_id, verified_on_date, session.user.id)
                    elsif verification_status == Constants::Verification::VERIFIED_REJECTED 
                        ClientVerification.record_CPV2_rejected(id,verified_by_staff_id, verified_on_date, session.user.id)
                    end
                  end
              end
       end
   end
   #get data required to show the filter form and the pending verifications form 
   get_data(params)
    
   @show_pending = true
   @show_recorded = true
   render :verifications
  end

  #default page
  def index
    render :verifications
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
