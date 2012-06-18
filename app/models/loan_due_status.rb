class LoanDueStatus
  include DataMapper::Resource
  include Constants::Properties, Constants::Loan, Constants::LoanAmounts
  
  property :id,                             Serial
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

  def self.generate_loan_due_status(for_loan_id, on_date)
    debugger
    loan = Lending.get(for_loan_id)
    raise Errors::DataError, "Unable to locate the loan for ID: #{for_loan_id}" unless loan

    location_map = LoanAdministration.get_locations(for_loan_id, on_date)
    raise Errors::DataError, "Unable to determine loan locations" unless location_map

    administered_at_id = location_map[ADMINISTERED_AT].id
    accounted_at_id    = location_map[ACCOUNTED_AT].id

    due_status = {}
    due_status[:lending_id]      = for_loan_id
    due_status[:due_status]      = loan.current_due_status
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
