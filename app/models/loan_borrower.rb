class LoanBorrower
  include DataMapper::Resource
  include Constants::Properties, Constants::Transaction

  property :id,                     Serial
  property :counterparty_type,      Enum.send('[]', *COUNTERPARTIES), :nullable => false
  property :counterparty_id,        *INTEGER_NOT_NULL
  property :effective_on,           *DATE_NOT_NULL
  property :administered_at_origin, *INTEGER_NOT_NULL
  property :accounted_at_origin,    *INTEGER_NOT_NULL
  property :performed_by,           *INTEGER_NOT_NULL
  property :recorded_by,            *INTEGER_NOT_NULL
  property :created_at,             *CREATED_AT

  has 1, :lending

  # Creates a record for a loan applied for a counterparty
  def self.assign_loan_borrower(to_counterparty, applied_on_date, administered_at_origin, accounted_at_origin, performed_by, recorded_by)
    Validators::Arguments.not_nil?(to_counterparty, applied_on_date, administered_at_origin, accounted_at_origin, performed_by, recorded_by)
    borrower = {}
    counterparty_type, counterparty_id = Resolver.resolve_counterparty(to_counterparty)
    borrower[:counterparty_type]       = counterparty_type
    borrower[:counterparty_id]         = counterparty_id
    borrower[:effective_on]            = applied_on_date
    borrower[:administered_at_origin]  = administered_at_origin
    borrower[:accounted_at_origin]     = accounted_at_origin
    borrower[:performed_by]            = performed_by
    borrower[:recorded_by]             = recorded_by
    new_loan_borrower = create(borrower)
    raise Errors::DataError, new_loan_borrower.errors.first.first unless new_loan_borrower.saved?
    new_loan_borrower
  end

  # Gets all loans for a counterparty
  def self.get_all_loans_for_counterparty(for_counterparty)
    counterparty_type, counterparty_id = Resolver.resolve_counterparty(for_counterparty)
    loans  = {}
    loans[:counterparty_type] = counterparty_type
    loans[:counterparty_id]   = counterparty_id
    all_loan_borrowers = all(loans)
    all_loan_borrowers.collect {|loan_borrower| loan_borrower.lending}
  end

  def self.aggregate_loans_applied(aggregate_by, on_date)
    loans_applied = {}
    loans_applied[:effective_on] = on_date
    loan_borrowers = all(loans_applied)
    loans = loan_borrowers.collect{|borrower| borrower.lending}
    group_by_type = resolve_aggregate_by(aggregate_by)
    loans.group_by {|loan| loan.send(group_by_type) if loan}
  end

  def self.resolve_aggregate_by(aggregate_by)
    case aggregate_by
      when ReportingFacade::AGGREGATE_BY_BRANCH then :accounted_at_origin
      when ReportingFacade::AGGREGATE_BY_CENTER then :administered_at_origin
      else
        raise Errors::OperationNotSupportedError, "Does not support aggregation by #{aggregate_by}"
    end
  end

end
