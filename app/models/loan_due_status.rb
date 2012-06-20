class LoanDueStatus
  include DataMapper::Resource
  include Constants::Properties, Constants::Loan, Constants::LoanAmounts, LoanLifeCycle
  include Comparable
  
  property :id,                             Serial
  property :loan_status,                    Enum.send('[]', *LOAN_STATUSES), :nullable => false
  property :due_status,                     Enum.send('[]', *LOAN_DUE_STATUSES), :nullable => false
  property :administered_at,                *INTEGER_NOT_NULL
  property :accounted_at,                   *INTEGER_NOT_NULL
  property :on_date,                        *DATE_NOT_NULL
  property SCHEDULED_PRINCIPAL_OUTSTANDING, *MONEY_AMOUNT
  property SCHEDULED_INTEREST_OUTSTANDING,  *MONEY_AMOUNT
  property SCHEDULED_TOTAL_OUTSTANDING,     *MONEY_AMOUNT
  property SCHEDULED_PRINCIPAL_DUE,         *MONEY_AMOUNT
  property SCHEDULED_INTEREST_DUE,          *MONEY_AMOUNT
  property SCHEDULED_TOTAL_DUE,             *MONEY_AMOUNT
  property ACTUAL_PRINCIPAL_OUTSTANDING,    *MONEY_AMOUNT
  property ACTUAL_INTEREST_OUTSTANDING,     *MONEY_AMOUNT
  property ACTUAL_TOTAL_OUTSTANDING,        *MONEY_AMOUNT
  property ACTUAL_PRINCIPAL_DUE,            *MONEY_AMOUNT
  property ACTUAL_INTEREST_DUE,             *MONEY_AMOUNT
  property ACTUAL_TOTAL_DUE,                *MONEY_AMOUNT
  property :principal_received_on_date,     *MONEY_AMOUNT
  property :interest_received_on_date,      *MONEY_AMOUNT
  property :principal_received_till_date,   *MONEY_AMOUNT
  property :interest_received_till_date,    *MONEY_AMOUNT
  property :advance_received_on_date,       *MONEY_AMOUNT
  property :advance_adjusted_on_date,       *MONEY_AMOUNT
  property :advance_received_till_date,     *MONEY_AMOUNT
  property :advance_adjusted_till_date,     *MONEY_AMOUNT
  property :advance_balance,                *MONEY_AMOUNT
  property :currency,                       *CURRENCY
  property :created_at,                     *CREATED_AT

  belongs_to :lending

  def administered_at_location; BizLocation.get(self.administered_at); end
  def accounted_at_location; BizLocation.get(self.accounted_at); end

  def <=>(other)
    return nil unless other.is_a?(LoanDueStatus)
    compare_on_date = other.on_date <=> self.on_date
    (compare_on_date == 0) ? (other.created_at <=> self.created_at) : compare_on_date
  end

  def is_overdue?
    self.due_status == OVERDUE
  end

  # The number of consecutive days upto the specified date; that the loan was overdue
  def self.unbroken_days_past_due(for_loan_id, on_date)
    generate_due_status_records_till_date(for_loan_id, on_date)
    days_past_due_till_date = all(:lending_id => for_loan_id, :on_date.lte => on_date).sort
    days_past_due_on_date = days_past_due_till_date.first
    return 0 unless days_past_due_on_date.is_overdue?
    unbroken_days_past_due = 0
    days_past_due_till_date.each { |due_status_record|
      if due_status_record.is_overdue?
        unbroken_days_past_due += 1
      else
        break
      end
    }
    unbroken_days_past_due
  end

  # The total number of days (not necessarily consecutive) that a loan was overdue upto the specified date
  def self.cumulative_days_past_due(for_loan_id, on_date)
    #TODO
  end

  # A list of the series of dates that the loan was overdue on consecutive days.
  # When the loan is overdue on two consecutive days, these days will belong to a range
  def self.days_past_due_episodes(for_loan_id, on_date)
    #TODO
  end

  def self.generate_loan_due_status(for_loan_id, on_date)
    loan = Lending.get(for_loan_id)
    raise Errors::DataError, "Unable to locate the loan for ID: #{for_loan_id}" unless loan

    location_map = LoanAdministration.get_locations(for_loan_id, on_date)
    raise Errors::DataError, "Unable to determine loan locations" unless location_map

    administered_at_id = location_map[ADMINISTERED_AT].id
    accounted_at_id    = location_map[ACCOUNTED_AT].id

    due_status = {}
    due_status[:lending_id]      = for_loan_id
    due_status[:loan_status]     = loan.current_loan_status
    due_status[:due_status]      = loan.due_status_from_outstanding(on_date)
    due_status[:administered_at] = administered_at_id
    due_status[:accounted_at]    = accounted_at_id
    due_status[:on_date]         = on_date

    due_status_amounts = {}
    due_status_amounts[SCHEDULED_PRINCIPAL_OUTSTANDING] = loan.scheduled_principal_outstanding(on_date)
    due_status_amounts[SCHEDULED_INTEREST_OUTSTANDING]  = loan.scheduled_interest_outstanding(on_date)
    due_status_amounts[SCHEDULED_TOTAL_OUTSTANDING]     = loan.scheduled_total_outstanding(on_date)
    due_status_amounts[SCHEDULED_PRINCIPAL_DUE]         = loan.scheduled_principal_due(on_date)
    due_status_amounts[SCHEDULED_INTEREST_DUE]          = loan.scheduled_interest_due(on_date)
    due_status_amounts[SCHEDULED_TOTAL_DUE]             = loan.scheduled_total_due(on_date)
    due_status_amounts[ACTUAL_PRINCIPAL_OUTSTANDING]    = loan.actual_principal_outstanding(on_date)
    due_status_amounts[ACTUAL_INTEREST_OUTSTANDING]     = loan.actual_interest_outstanding(on_date)
    due_status_amounts[ACTUAL_TOTAL_OUTSTANDING]        = loan.actual_total_outstanding(on_date)
    due_status_amounts[ACTUAL_PRINCIPAL_DUE]            = loan.actual_principal_due(on_date)
    due_status_amounts[ACTUAL_INTEREST_DUE]             = loan.actual_interest_due(on_date)
    due_status_amounts[ACTUAL_TOTAL_DUE]                = loan.actual_total_due(on_date)
    due_status_amounts[:principal_received_on_date]     = loan.principal_received_on_date(on_date)
    due_status_amounts[:interest_received_on_date]      = loan.interest_received_on_date(on_date)
    due_status_amounts[:principal_received_till_date]   = loan.principal_received_till_date(on_date)
    due_status_amounts[:interest_received_till_date]    = loan.interest_received_till_date(on_date)
    due_status_amounts[:advance_received_on_date]       = loan.advance_received_on_date(on_date)
    due_status_amounts[:advance_adjusted_on_date]       = loan.advance_adjusted_on_date(on_date)
    due_status_amounts[:advance_received_till_date]     = loan.advance_received_till_date(on_date)
    due_status_amounts[:advance_adjusted_till_date]     = loan.advance_adjusted_till_date(on_date)
    due_status_amounts[:advance_balance]                = loan.advance_balance(on_date)
    due_status.merge!(Money.from_money(due_status_amounts))
    
    loan_due_status_record = create(due_status)
    raise Errors::DataError, loan_due_status_record.errors.first.first unless loan_due_status_record.saved?
    loan_due_status_record
  end

  # If a record exists on any date, get the most recent record on the date
  # If a record does not exist on any date, generate a record, then return the most recent record on the date
  def self.most_recent_status_record_on_date(for_loan_id, on_date)
    status_records_on_date = all(:lending_id => for_loan_id, :on_date => on_date)
    most_recent_status = status_records_on_date.most_recent_status_record
    most_recent_status || generate_loan_due_status(for_loan_id, on_date)
  end

  def self.generate_due_status_records_till_date(for_loan_id, on_date)
    loan = Lending.get(for_loan_id)
    raise Errors::DataError, "Unable to locate the loan for ID: #{for_loan_id}" unless loan

    scheduled_first_repayment_date = loan.scheduled_first_repayment_date
    return unless (loan.disbursal_date and (on_date >= scheduled_first_repayment_date))

    (scheduled_first_repayment_date..on_date).each { |each_date|
      most_recent_status_record_on_date(for_loan_id, each_date)
    }
  end

  def self.most_recent_status_record
    first(:order => [:on_date.desc, :created_at.desc])
  end

  def money_amounts
    [
      SCHEDULED_PRINCIPAL_OUTSTANDING,
      SCHEDULED_INTEREST_OUTSTANDING,
      SCHEDULED_TOTAL_OUTSTANDING,
      SCHEDULED_PRINCIPAL_DUE,
      SCHEDULED_INTEREST_DUE,
      SCHEDULED_TOTAL_DUE,
      ACTUAL_PRINCIPAL_OUTSTANDING,
      ACTUAL_INTEREST_OUTSTANDING,
      ACTUAL_TOTAL_OUTSTANDING,
      ACTUAL_PRINCIPAL_DUE,
      ACTUAL_INTEREST_DUE,
      ACTUAL_TOTAL_DUE,
      :principal_received_on_date,
      :interest_received_on_date,
      :principal_received_till_date,
      :interest_received_till_date,
      :advance_received_on_date,
      :advance_adjusted_on_date,
      :advance_received_till_date,
      :advance_adjusted_till_date,
      :advance_balance
    ]
  end

end