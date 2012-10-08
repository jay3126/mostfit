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
  property :last_payment_date,   *Date
  property :assignment_type,     Enum.send('[]', *TRANCH_ASSIGNMENT_TYPES), :default => Constants::TranchAssignment::NOT_ASSIGNED
  property :created_by,          Integer
  property :created_at,          *CREATED_AT

  belongs_to :new_funding_line

  def money_amounts; [:amount]; end
  def tranch_money_amount; to_money_amount(:amount); end
end