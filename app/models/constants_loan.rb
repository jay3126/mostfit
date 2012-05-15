module Constants
  module Loan
    
    DISBURSEMENT = :disbursement; REPAYMENT = :repayment
    LOAN_PAYMENT_TYPES = [ DISBURSEMENT, REPAYMENT ]

    NEW = :new; CREATED = :created; APPROVED = :approved; REJECTED = :rejected;
    DISBURSED = :disbursed; CANCELLED = :cancelled; REPAID = :repaid
    LOAN_STATUSES = [ NEW, CREATED, APPROVED, REJECTED, DISBURSED, CANCELLED, REPAID ]

    NOT_DUE = :not_due; DUE = :due; OVERDUE = :overdue
    LOAN_DUE_STATUSES = [ NOT_DUE, DUE, OVERDUE ]

    PERMISSIBLE_LOAN_STATUS_CHANGES = {
      CREATED => [APPROVED, REJECTED],
      APPROVED => [DISBURSED, CANCELLED],
      REJECTED => [],
      CANCELLED => [],
      DISBURSED => [CANCELLED, REPAID],
      REPAID => []
    }

    INTEREST_RATE_PRECISION = 65
    INTEREST_RATE_SCALE = 2

  end
end
