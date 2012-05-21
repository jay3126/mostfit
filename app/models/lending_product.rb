class LendingProduct
  include DataMapper::Resource
  include Constants::Properties, Constants::Money, Constants::Loan, Constants::LoanAmounts, MarkerInterfaces::Recurrence
  
  property :id,                             Serial
  property :name,                           *NAME
  property :amount,                         *MONEY_AMOUNT
  property :currency,                       *CURRENCY
  property :interest_rate,                  *FLOAT_NOT_NULL
  property :repayment_frequency,            *FREQUENCY
  property :tenure,                         *TENURE
  property :repayment_allocation_strategy,  Enum.send('[]', *LOAN_REPAYMENT_ALLOCATION_STRATEGIES), :nullable => false
  property :created_at,                     *CREATED_AT

  def money_amounts; [:amount]; end

  has 1, :loan_schedule_template
  has n, :lendings

  # Implementing MarkerInterfaces::Recurrence#frequency
  def frequency; self.repayment_frequency; end

  def amortization; self.loan_schedule_template.amortization; end

  def total_interest_money_amount
    self.loan_schedule_template.total_interest_money_amount
  end

end
