module Constants
  # All constants for use in the application should be namespaces under further modules under this module

  module Status
    #All constants that are related to statuses, handle with care

    CREATED_STATUS = :created; SENT_STATUS = :sent
    REQUEST_STATUSES = [CREATED_STATUS, SENT_STATUS, :response_received]

    NEW_STATUS = :new; APPROVED_STATUS = :approved
    APPLICATION_STATUSES = [NEW_STATUS, :pending_overlap_report, :overlap_report_cleared, :overlap_report_rejected, APPROVED_STATUS, :rejected, :on_hold]
    
  end

end