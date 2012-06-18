class LoanStatusChange
  include DataMapper::Resource
  include LoanLifeCycle
  include Constants::Properties

  # All status change transitions are recorded here as a trail

  property :id,           Serial
  property :from_status,  Enum.send('[]', *LOAN_STATUSES), :nullable => false
  property :to_status,    Enum.send('[]', *LOAN_STATUSES), :nullable => false
  property :effective_on, *DATE_NOT_NULL
  property :created_at,   *CREATED_AT

  validates_with_method :dissimilar_statuses?

  belongs_to :lending

  # from_status and to_status should be different
  def dissimilar_statuses?
    from_status == to_status ? [false, "There does not seem to be any loan status change from: #{from_status} to: #{to_status}"] : true
  end

  # Records the loan status change
  def self.record_status_change(loan, old_status, new_status, effective_on)
    status_change                = {}
    status_change[:lending]      = loan
    status_change[:from_status]  = old_status
    status_change[:to_status]    = new_status
    status_change[:effective_on] = effective_on
    status_change_record = create(status_change)
    raise Errors::DataError, status_change_record.errors.first.first unless status_change_record.saved?
    status_change_record
  end

  def self.status_in_force(on_or_before_date)
    debugger
    in_force = {}
    in_force[:effective_on.lte] = on_or_before_date
    in_force[:order]            = [:effective_on.desc]
    first(in_force)
  end

end
