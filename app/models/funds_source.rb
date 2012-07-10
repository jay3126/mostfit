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

end
