class LoanReceipt
  include DataMapper::Resource
  include Constants::Properties, Constants::LoanAmounts

  property :id,                Serial
  property PRINCIPAL_RECEIVED, *MONEY_AMOUNT
  property INTEREST_RECEIVED,  *MONEY_AMOUNT
  property ADVANCE_RECEIVED,   *MONEY_AMOUNT
  property ADVANCE_ADJUSTED,   *MONEY_AMOUNT
  property :currency,          *CURRENCY
  property :performed_at,      *INTEGER_NOT_NULL
  property :accounted_at,      *INTEGER_NOT_NULL
  property :effective_on,      *DATE_NOT_NULL
  property :created_at,        *CREATED_AT

  def money_amounts
    [PRINCIPAL_RECEIVED, INTEREST_RECEIVED, ADVANCE_RECEIVED, ADVANCE_ADJUSTED]
  end

  belongs_to :lending

  # Record the principal, interest, and advance amounts received on a loan on the specified value date
  # @param [Hash] allocation_values such as {:principal_received => principal_received_money_obj, :interest_received => interest_received_money_obj, :advance_received => advance_received_money_obj}
  # @param [Lending] on_loan
  # @param [Date] effective_on
  def self.record_allocation_as_loan_receipt(allocation_values, performed_at, accounted_at, on_loan, effective_on)
    Validators::Arguments.not_nil?(allocation_values, performed_at, accounted_at, on_loan, effective_on)
    receipt                     = Money.from_money(allocation_values)
    receipt.delete(TOTAL_RECEIVED)
    receipt[:performed_at]      = performed_at
    receipt[:accounted_at]      = accounted_at
    receipt[:lending]           = on_loan
    receipt[:effective_on]      = effective_on
    loan_receipt                = create(receipt)
    raise Errors::DataError, loan_receipt.errors.first.first unless loan_receipt.saved?
    loan_receipt
  end

  # Sum of all receipts only on the specified date
  def self.sum_on_date(on_date = Date.today)
    matching_date                = { }
    matching_date[:effective_on] = on_date
    all_receipts                 = all(matching_date)
    add_up(all_receipts)
  end

  # Sum of all receipts upto and including the specified date
  def self.sum_till_date(on_date = Date.today)
    matching_date                    = { }
    matching_date[:effective_on.lte] = on_date
    all_receipts                     = all(matching_date)
    add_up(all_receipts)
  end

  private

  # Add up the money amounts on receipt and return a hash with the correct keys
  def self.add_up(receipts)
    zero_money = MoneyManager.default_zero_money
    totals                     = { }
    totals[PRINCIPAL_RECEIVED] = zero_money
    totals[INTEREST_RECEIVED]  = zero_money
    totals[ADVANCE_RECEIVED]   = zero_money
    totals[ADVANCE_ADJUSTED]   = zero_money
    
    unless receipts.empty?
      all_money_receipts = receipts.collect { |receipt| receipt.to_money }

      all_principal_amounts = all_money_receipts.collect { |receipt| receipt[PRINCIPAL_RECEIVED] }
      totals[PRINCIPAL_RECEIVED] = all_principal_amounts.reduce(:+) unless all_principal_amounts.empty?

      all_interest_amounts = all_money_receipts.collect { |receipt| receipt[INTEREST_RECEIVED] }
      totals[INTEREST_RECEIVED] = all_interest_amounts.reduce(:+) unless all_interest_amounts.empty?

      all_advance_received_amounts = all_money_receipts.collect { |receipt| receipt[ADVANCE_RECEIVED] }
      totals[ADVANCE_RECEIVED] = all_advance_received_amounts.reduce(:+) unless all_advance_received_amounts.empty?

      all_advance_adjusted_amounts = all_money_receipts.collect { |receipt| receipt[ADVANCE_ADJUSTED] }
      totals[ADVANCE_ADJUSTED] = all_advance_adjusted_amounts.reduce(:+) unless all_advance_adjusted_amounts.empty?
    end

    Money.add_total_to_map(totals, :total_received)
  end

end
