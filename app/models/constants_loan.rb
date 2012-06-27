module Constants
  module Loan
    
    DISBURSEMENT = :disbursement; REPAYMENT = :repayment
    LOAN_PAYMENT_TYPES = [ DISBURSEMENT, REPAYMENT ]

    NOT_APPLICABLE = :not_applicable; NOT_DUE = :not_due; DUE = :due; OVERDUE = :overdue
    LOAN_DUE_STATUSES = [ NOT_APPLICABLE, NOT_DUE, DUE, OVERDUE ]

    ADMINISTERED_AT = :administered_at
    ACCOUNTED_AT    = :accounted_at

    DISBURSE_LOAN_ACTION = :disburse_loan_action; REPAY_LOAN_ACTION = :repay_loan_action
    LOAN_ACTIONS = [ DISBURSE_LOAN_ACTION, REPAY_LOAN_ACTION ]

    INTEREST_RATE_PRECISION = 65
    INTEREST_RATE_SCALE = 2

  end
end
