class LoanAssignment
  include DataMapper::Resource
  include Constants::Properties, Constants::LoanAssignment

  # A LoanAssignment indicates that a specific loan has now been marked to either a securitization or an encumberance effective_on date

  property :id,                       Serial
  property :loan_id,                  *INTEGER_NOT_NULL
  property :assignment_nature,        Enum.send('[]', *LOAN_ASSIGNMENT_NATURE), :nullable => false
  property :assignment_status,        Enum.send('[]', *LOAN_ASSIGNMENT_STATUSES), :nullable => false
  property :effective_on,             *DATE_NOT_NULL
  property :funder_id,                *INTEGER_NOT_NULL
  property :funding_line_id,          *INTEGER_NOT_NULL
  property :tranch_id,                *INTEGER_NOT_NULL
  property :is_additional_encumbered, Boolean, :default => false
  property :recorded_by,              *INTEGER_NOT_NULL
  property :created_at,               *CREATED_AT
  property :deleted_at,               *DELETED_AT

  validates_with_method :loan_exists?, :is_loan_outstanding_on_date?

  def cannot_both_sell_and_encumber
    validate_value = true
    if self.new?
      any_loan_assignment = LoanAssignment.last(:loan_id => self.loan_id)
      validate_value = (any_loan_assignment.blank? || any_loan_assignment.is_additional_encumbered) ? true :
        [false, "There is already an assignment for the loan with ID #{self.loan_id} in effect"]
    end
    validate_value
  end

  def loan_exists?
    Lending.get(self.loan_id) ? true : [false, "There is no loan with ID: #{self.loan_id}"]
  end

  def is_loan_outstanding_on_date?
    loan = Lending.get(self.loan_id)
    loan.is_outstanding_on_date?(self.effective_on) ? true : [false, "The loan with ID: #{self.loan_id} is not oustanding on requested date: #{self.effective_on}"]
  end

  def effective_after_assignment_date?
    validation = true
    assignment = self.loan_assignment_instance
    if (assignment)
      validation = (self.effective_on >= assignment.created_on) ? true :
        [false, "Loan assignment date: #{self.effective_on} cannot precede the date of creation of #{assignment.to_s}"]
    end
    validation
  end

  def loan_assignment_instance
    Resolver.fetch_assignment(self.assignment_nature)
  end
  
  # Marks a loan as assigned to a securitization or encumberance instance effective_on the specified date, performed_by the staff member and recorded_by user
  def self.assign(loan_id, to_assignment, recorded_by)
    new_assignment                     = {}
    new_assignment[:loan_id]           = loan_id
    assignment_nature                  = Resolver.resolve_loan_assignment(to_assignment)
    new_assignment[:assignment_nature] = assignment_nature
    new_assignment[:assignment_status] = ASSIGNED
    new_assignment[:effective_on]      = to_assignment.effective_on
    new_assignment[:recorded_by]       = recorded_by
    
    assignment = create(new_assignment)
    raise Errors::DataError, assignment.errors.first.first unless assignment.saved?
    assignment
  end

  def self.assign_on_date(loan_id, assignment_nature, on_date, funder_id, funding_line_id, tranch_id, recorded_by, additional_encumbered = false)
    new_assignment                     = {}
    new_assignment[:loan_id]           = loan_id
    new_assignment[:assignment_nature] = assignment_nature
    new_assignment[:assignment_status] = ASSIGNED
    new_assignment[:funder_id]         = funder_id
    new_assignment[:funding_line_id]   = funding_line_id
    new_assignment[:tranch_id]         = tranch_id
    new_assignment[:effective_on]      = on_date
    new_assignment[:recorded_by]       = recorded_by
    new_assignment[:is_additional_encumbered] = additional_encumbered
    assignment = create(new_assignment)
    raise Errors::DataError, assignment.errors.first.first unless assignment.saved?
    assignment
  end

  # Finds the most recent assignment for loan on the date
  def self.get_loan_assigned_to(for_loan_id, on_date)
    for_loan_on_date = {}
    for_loan_on_date[:loan_id]           = for_loan_id
    for_loan_on_date[:assignment_status] = ASSIGNED
    #    for_loan_on_date[:effective_on.lte]  = on_date
    #    for_loan_on_date[:order]             = [:effective_on.desc]
    last(for_loan_on_date)
  end

  # Returns a list of loan IDs that are assigned to an instance of securitization or encumberance, on a specific date
  # 
  def self.get_loans_assigned(to_assignment, on_date=nil)
    assignment_nature = Resolver.resolve_loan_assignment(to_assignment)
    if ((assignment_nature == Constants::LoanAssignment::ENCUMBERED) and (on_date.nil?))
      raise ArgumentError, "Effective date must be supplied for encumberance"
    end
    loan_assignments = []
    query = {}
    query[:assignment_nature] = assignment_nature
    query[:effective_on.lte]  = on_date if on_date
    query[:assignment_status] = ASSIGNED
    loan_assignments = all(query)
    loan_assignments.collect {|assignment| assignment.loan_id}
  end

  # Returns a list of loan IDs that are assigned to an instance of securitization or encumberance, for a date range.
  def self.get_loans_assigned_in_date_range(assignment_nature, on_date, till_date)
    earlier_date, later_date = on_date <= till_date ? [on_date, till_date] : [till_date, on_date]
    loan_assignments = []
    query = {}
    query[:assignment_nature] = assignment_nature
    query[:effective_on.gte]  = earlier_date if earlier_date
    query[:effective_on.lte]  = later_date if later_date
    query[:assignment_status] = ASSIGNED
    loan_assignments = all(query)
    loan_assignments.collect {|assignment| assignment.loan_id}
  end

  # Indicates the loan assignment status on a specified date
  def self.get_loan_assignment_status(for_loan_id, on_date)
    assignment = get_loan_assigned_to(for_loan_id, on_date)
    assignment ? assignment.assignment_nature : NOT_ASSIGNED
  end

  def self.loan_assignment_status_message(loan_id, on_date = Date.today)
    loan_assigned_to = get_loan_assigned_to(loan_id, on_date)
    return loan_assigned_to.nil? ? "Not Assigned" : loan_assigned_to.loan_assignment_status
  end

  def loan_assignment_status
    assignment_nature_str = is_additional_encumbered ? "Additional Encumbered" : assignment_nature.humanize rescue nil
    "<b>#{assignment_nature_str}</b> (Effective On: #{effective_on})"
  end

  def self.get_loans_assigned_to_tranch(to_tranch)
    LoanAssignment.all(:tranch_id => to_tranch.id).aggregate(:loan_id)
  end

end