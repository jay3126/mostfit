module Constants
  # All constants for use in the application should be namespaces under further modules under this module

  module Status
    #All constants that are related to statuses, handle with care

    CREATED_STATUS = :created; SENT_STATUS = :sent
    REQUEST_STATUSES = [CREATED_STATUS, SENT_STATUS, :response_received]

    NEW_STATUS = :new; APPROVED_STATUS = :approved
    APPLICATION_STATUSES = [NEW_STATUS, :pending_overlap_report, :overlap_report_cleared, :overlap_report_rejected, APPROVED_STATUS, :rejected, :on_hold]

    LOAN_OUTSTANDING_STATUS = :outstanding
    LOAN_STATUSES = [LOAN_OUTSTANDING_STATUS]
    
  end

  module Verification
    
    CPV1 = 'cpv1'; CPV2 = 'cpv2'
    CLIENT_VERIFICATION_TYPES = [CPV1, CPV2]

    NOT_VERIFIED = 'not_verified'; VERIFIED_ACCEPTED = 'verified_accepted'; VERIFIED_REJECTED = 'verified_rejected'
    CLIENT_VERIFICATION_STATUSES = [NOT_VERIFIED, VERIFIED_ACCEPTED, VERIFIED_REJECTED]

  end

end