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

  def self.most_recent_status_record
    first(:order => [:on_date.desc, :created_at.desc])
  end

  def self.most_recent_status_and_date
    status_record = most_recent_status_record
    [ status_record.lending_id, status_record.due_status, status_record.on_date ]
  end

end
