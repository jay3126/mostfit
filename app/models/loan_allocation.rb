class LoanAllocation
  include DataMapper::Resource
  include Constants::Properties, Constants::Transaction

  property :id,           Serial
  property :on_date,      *DATE_NOT_NULL
  property :receipt_type, Enum.send('[]', *RECEIVED_OR_PAID), :nullable => false
  property :principal,    *MONEY_AMOUNT
  property :interest,     *MONEY_AMOUNT
  property :created_at,   *CREATED_AT

  belongs_to :lending

  def self.all_receipts(on_loan, on_or_before_date = nil)
    query = query_loan_on_or_before_date(on_loan, on_or_before_date)
    query[:receipt_type] = RECEIPT
    all(query)
  end

  def self.all_payments(on_loan, on_or_before_date = nil)
    query = query_loan_on_or_before_date(on_loan, on_or_before_date)
    query[:receipt_type] = PAYMENT
    all(query)
  end

  private

  def self.query_loan_on_or_before_date(on_loan, on_or_before_date = nil)
    query = {}
    query[:lending] = on_loan
    query[:on_date.lte] = on_or_before_date if on_or_before_date
    query
  end

end
