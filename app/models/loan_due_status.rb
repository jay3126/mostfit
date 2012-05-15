class LoanDueStatus
  include DataMapper::Resource
  include Constants::Properties, Constants::Loan
  
  property :id,                      Serial
  property :due_status,              Enum.send('[]', *LOAN_DUE_STATUSES), :nullable => false
  property :on_date,                 *DATE_NOT_NULL
  property :total_principal_repaid,  *MONEY_AMOUNT
  property :total_interest_received, *MONEY_AMOUNT
  property :currency,                *CURRENCY
  property :created_at,              *CREATED_AT

  belongs_to :lending

end
