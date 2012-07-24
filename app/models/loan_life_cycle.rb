module LoanLifeCycle

  def current_loan_status
    raise TypeError, "Does not implement status" unless (respond_to?(:status) and status)
    status
  end

  def is_approved?
    LoanLifeCycle.is_approved_status?(current_loan_status)
  end

  def is_disbursed?
    LoanLifeCycle.is_disbursed_status?(current_loan_status)
  end

  def is_outstanding?
    LoanLifeCycle.is_outstanding_status?(current_loan_status)
  end

  def is_repaid?
    LoanLifeCycle.is_repaid_status?(current_loan_status)
  end

  def is_written_off?
    LoanLifeCycle.is_written_off_status?(current_loan_status)
  end

  # Use the below to test status in general
  def self.is_approved_status?(status)
    validate_status(status)
    (status == APPROVED_LOAN_STATUS) or is_disbursed_status?(status)
  end
  
  def self.is_disbursed_status?(status)
    validate_status(status)
    LOAN_STATUSES.index(status) >= LOAN_STATUSES.index(DISBURSED_LOAN_STATUS)
  end
  
  def self.is_outstanding_status?(status)
    validate_status(status)
    (status == DISBURSED_LOAN_STATUS)    
  end
  
  def self.is_repaid_status?(status)
    validate_status(status)
    status == REPAID_LOAN_STATUS
  end

  def self.is_written_off_status?(status)
    validate_status(status)
    status == WRITTEN_OFF_LOAN_STATUS
  end

  def self.validate_status(status)
    raise ArgumentError, "Status #{status} is not recognised" unless LOAN_STATUSES.include?(status)
  end

  STATUS_NOT_SPECIFIED    = :status_not_specified
  NEW_LOAN_STATUS         = :new_loan_status
  APPROVED_LOAN_STATUS    = :approved_loan_status
  REJECTED_LOAN_STATUS    = :rejected_loan_status
  DISBURSED_LOAN_STATUS   = :disbursed_loan_status
  CANCELLED_LOAN_STATUS   = :cancelled_loan_status
  REPAID_LOAN_STATUS      = :repaid_loan_status
  WRITTEN_OFF_LOAN_STATUS = :written_off_loan_status

  LOAN_STATUSES = [STATUS_NOT_SPECIFIED, NEW_LOAN_STATUS, APPROVED_LOAN_STATUS, REJECTED_LOAN_STATUS, DISBURSED_LOAN_STATUS, CANCELLED_LOAN_STATUS, REPAID_LOAN_STATUS, WRITTEN_OFF_LOAN_STATUS]

  REPAID_IN_FULL = :repaid_in_full
  PRECLOSED      = :preclosed
  REPAID_SHORT   = :repaid_short
  REPAID_NATURES = [REPAID_IN_FULL, PRECLOSED, REPAID_SHORT]

  REPAYMENT_ACTIONS_AND_REPAID_NATURES = {
    Constants::Transaction::LOAN_REPAYMENT => REPAID_IN_FULL,
    Constants::Transaction::LOAN_PRECLOSURE => PRECLOSED,
    Constants::Transaction::LOAN_ADVANCE_ADJUSTMENT => REPAID_IN_FULL
  }

  STATUSES_DATES_SUM_AMOUNTS = {
    :applied => [NEW_LOAN_STATUS, :applied_on_date, :applied_amount.sum],
    :approved => [APPROVED_LOAN_STATUS, :approved_on_date, :approved_amount.sum],
    :scheduled_for_disbursement => [APPROVED_LOAN_STATUS, :scheduled_disbursal_date, :approved_amount.sum],
    :disbursed => [DISBURSED_LOAN_STATUS, :disbursal_date, :disbursed_amount.sum]
  }

end
