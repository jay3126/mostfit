class NewTranch
  include DataMapper::Resource
  include Constants::Properties
  include Constants::TranchAssignment

  property :id,                  Serial
  property :amount,              *MONEY_AMOUNT
  property :currency,            *CURRENCY
  property :interest_rate,       *FLOAT_NOT_NULL
  property :disbursal_date,      *Date
  property :first_payment_date,  *Date
  property :last_payment_date,   Date
  property :assignment_type,     Enum.send('[]', *TRANCH_ASSIGNMENT_TYPES), :default => Constants::TranchAssignment::NOT_ASSIGNED
  property :created_by,          Integer
  property :created_at,          *CREATED_AT

  belongs_to :new_funding_line

  validates_with_method  :disbursal_date,       :method => :disbursal_not_in_past?
  validates_with_method  :first_payment_date,   :method => :first_payment_not_equalto_disbursal?
  validates_with_method  :first_payment_date,   :method => :first_payment_not_before_disbursal?
  validates_with_method  :last_payment_date,    :method => :last_payment_not_before_first_payment_or_disbursal?
  validates_present      :amount, :interest_rate, :disbursal_date, :first_payment_date, :assignment_type

  def money_amounts; [:amount]; end

  def tranch_money_amount; to_money_amount(:amount); end

  private

  def disbursal_not_in_past?
    return (!disbursal_date.blank? && disbursal_date < Date.today) ? [false, "Disbursal date must not be past date"] : true
  end

  def first_payment_not_before_disbursal?
    return ((!first_payment_date.blank? && first_payment_date < disbursal_date)) ? [false, "First payment date must not before disbursal date"] : true
  end

  def first_payment_not_equalto_disbursal?
    return ((!first_payment_date.blank? && first_payment_date == disbursal_date)) ? [false, "First payment date must not equal to disbursal date"] : true
  end

  def last_payment_not_before_first_payment_or_disbursal?
    return (!last_payment_date.blank? && ((last_payment_date < disbursal_date) || (last_payment_date < first_payment_date))) ? [false, "Last payment date must not before disbursal date or First Payment date"] : true
  end

end