module LoanLifeCycle

  # Obtain the current loan status
  def current_loan_status; status; end

  def is_disbursed?
    LOAN_STATUSES.index(current_loan_status) >= LOAN_STATUSES.index(DISBURSED_LOAN_STATUS)
  end

  STATUS_NOT_SPECIFIED  = :status_not_specified
  NEW_LOAN_STATUS       = :new_loan_status
  APPROVED_LOAN_STATUS  = :approved_loan_status
  REJECTED_LOAN_STATUS  = :rejected_loan_status
  DISBURSED_LOAN_STATUS = :disbursed_loan_status
  CANCELLED_LOAN_STATUS = :cancelled_loan_status
  REPAID_LOAN_STATUS    = :repaid_loan_status

  LOAN_STATUSES = [STATUS_NOT_SPECIFIED, NEW_LOAN_STATUS, APPROVED_LOAN_STATUS, REJECTED_LOAN_STATUS, DISBURSED_LOAN_STATUS, CANCELLED_LOAN_STATUS, REPAID_LOAN_STATUS]

end