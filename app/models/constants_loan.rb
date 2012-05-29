module Constants
  module Loan
    
    DISBURSEMENT = :disbursement; REPAYMENT = :repayment
    LOAN_PAYMENT_TYPES = [ DISBURSEMENT, REPAYMENT ]

    STATUS_NOT_SPECIFIED = :status_not_specified
    NEW_LOAN_STATUS = :new_loan_status; APPROVED_LOAN_STATUS = :approved_loan_status; REJECTED_LOAN_STATUS = :rejected_loan_status;
    DISBURSED_LOAN_STATUS = :disbursed_loan_status; CANCELLED_LOAN_STATUS = :cancelled_loan_status; REPAID_LOAN_STATUS = :repaid_loan_status
    LOAN_STATUSES = [ STATUS_NOT_SPECIFIED, NEW_LOAN_STATUS, APPROVED_LOAN_STATUS, REJECTED_LOAN_STATUS, DISBURSED_LOAN_STATUS, CANCELLED_LOAN_STATUS, REPAID_LOAN_STATUS ]

    NOT_DUE = :not_due; DUE = :due; OVERDUE = :overdue
    LOAN_DUE_STATUSES = [ NOT_DUE, DUE, OVERDUE ]

    ADMINISTERED_AT = :administered_at
    ACCOUNTED_AT    = :accounted_at

    INTEREST_RATE_PRECISION = 65
    INTEREST_RATE_SCALE = 2

  end
end
