class ClientVerifications < Application
  # provides :xml, :yaml, :js

  def index
    render :verifications
  end

  # Gives the loan applications pending for verification
  def pending_verifications
    get_data(params)
    get_pending_and_recent_recorded_verification(params)
    render :verifications
  end

  # Records the given CPVs and shows the list of recently recorded AND the other Loan Applications pending verifications
  def record_verifications
    get_data(params)
    
    # Show the recently recorded verifications
    if params.key?('verification_status')
      params['verification_status'].keys.each do | cpv_type |
        params['verification_status'][cpv_type].keys.each do | id |
          begin
            verified_by_staff_id = params['verified_by_staff_id'][cpv_type][id]
            verification_status = params['verification_status'][cpv_type][id]
            verified_on_date = params['verified_on_date'][cpv_type][id]
            client_verification = loan_applications_facade.find_cpv1_for_loan_application(id)
            if verified_by_staff_id.empty?
              @errors[id] = "Loan Application ID #{id} : Staff ID must be provided for #{cpv_type}"
              next
            elsif verified_on_date.empty?
              @errors[id] = "Loan Application ID #{id} : Verified-on Date must be provided for #{cpv_type}"
              next
            end
            unless client_verification.blank?
              cpv1_date = client_verification.verified_on_date
              raise "Loan Application ID #{id} : CPV2 verification date must not before CPV1 verification date" if cpv1_date > Date.parse(verified_on_date)
            end
            if cpv_type == Constants::Verification::CPV1
              if verification_status == Constants::Verification::VERIFIED_ACCEPTED
                loan_applications_facade.record_CPV1_approved(id,verified_by_staff_id, verified_on_date)
              elsif verification_status == Constants::Verification::VERIFIED_REJECTED
                loan_applications_facade.record_CPV1_rejected(id,verified_by_staff_id, verified_on_date)
              elsif verification_status == Constants::Verification::VERIFIED_PENDING
                loan_applications_facade.record_CPV1_pending(id,verified_by_staff_id, verified_on_date)
              end
            elsif cpv_type == Constants::Verification::CPV2
              if verification_status == Constants::Verification::VERIFIED_ACCEPTED
                loan_applications_facade.record_CPV2_approved(id,verified_by_staff_id, verified_on_date)
              elsif verification_status == Constants::Verification::VERIFIED_REJECTED
                loan_applications_facade.record_CPV2_rejected(id,verified_by_staff_id, verified_on_date)
              elsif verification_status == Constants::Verification::VERIFIED_PENDING
                loan_applications_facade.record_CPV2_pending(id,verified_by_staff_id, verified_on_date)
              end
            end
          rescue => ex
            @errors['CPV Recording'] = ex.message
          end
        end
      end
    else
      @errors['CPV Recording'] = "Choose verification status, either Approved or Rejected."
    end
    get_pending_and_recent_recorded_verification(params)
    # RENDER/RE-DIRECT
    render :verifications
  end

  private

  # fetch branch, center, pending verification and completed verification
  def get_data(params)
    # GATE-KEEPING
    @errors = {}
    @branch_id = params[:parent_location_id]
    @center_id = params[:child_location_id]

    # VALIDATIONS
    unless params[:flag] == 'true'
      if @branch_id.blank?
        @errors["'verification_status'"] = "Please select a branch"
      elsif @center_id.blank?
        @errors["'verification_status'"] = "Please select center"
      end
    end
  end

  def get_pending_and_recent_recorded_verification(params)
    # POPULATING RESPONSE AND OTHER VARIABLES
    @loan_applications_pending_verification = loan_applications_facade.pending_CPV({:at_branch_id => params[:parent_location_id], :at_center_id => params[:child_location_id]})
    @all_loan_applications = loan_applications_facade.get_all_loan_applications_for_branch_and_center({:at_branch_id => params[:parent_location_id], :at_center_id => params[:child_location_id]})
  end

end # ClientVerifications