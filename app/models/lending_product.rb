class LendingProduct
  include DataMapper::Resource
  include Constants::Properties, Constants::Money, Constants::Loan, MarkerInterfaces::Recurrence
  
  property :id,                  Serial
  property :name,                *NAME
  property :amount,              *MONEY_AMOUNT
  property :currency,            *CURRENCY
  property :interest_rate,       *FLOAT_NOT_NULL
  property :repayment_frequency, *FREQUENCY
  property :tenure,              *TENURE
  property :created_at,          *CREATED_AT

  has 1, :loan_schedule_template
  has n, :lendings

  # Implementing MarkerInterfaces::Recurrence#frequency
  def frequency; self.repayment_frequency; end

end
