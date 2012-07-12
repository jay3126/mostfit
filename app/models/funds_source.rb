class FundsSource
  include DataMapper::Resource
  include Constants::Properties

  property :id,           Serial
  property :name,         *NAME
  property :effective_on, *DATE_NOT_NULL
  property :created_at,   *CREATED_AT

  belongs_to :lending
  belongs_to :tranch

  validates_with_method :loan_and_tranch_dates_are_valid?

  def loan_and_tranch_dates_are_valid?
    Validators::Assignments.is_valid_assignment_date?(self.effective_on, self.lending, self.tranch)
  end

  #Assign a specific loan to a certain tranch as effective on a given date
  def self.assign_to_tranch_on_date(loan_id, tranch_id, on_date)
    new_assignment                     = {}
    new_assignment[:loan_id]           = loan_id
    new_assignment[:tranch_id]         = tranch_id
    new_assignment[:effective_on]      = on_date

    assignment = create(new_assignment)
    raise Errors::DataError, assignment.errors.first.first unless assignment.saved?
    assignment
  end

  #Returns a list of loan IDs that are assigned to an instance of Tranch, on a specific date
  def self.get_loans_assigned(to_tranch, on_date)
    if on_date.nil? 
        raise ArgumentError, "You need to pass a date"
    elsif on_date < to_tranch.date_of_commencement
        raise ArgumentError, "There cannot be any loans assigned before the date of commencent of tranch"
    end

    all(:tranch_id => to_tranch.id,
        :effective_on => on_date).collect { |assignment| assignment.loan_id }
  end

end
