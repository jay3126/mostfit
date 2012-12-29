class LoanReceipt
  include DataMapper::Resource
  include Constants::Properties, Constants::LoanAmounts

  property :id,                  Serial
  property PRINCIPAL_RECEIVED,   *MONEY_AMOUNT
  property INTEREST_RECEIVED,    *MONEY_AMOUNT
  property ADVANCE_RECEIVED,     *MONEY_AMOUNT
  property ADVANCE_ADJUSTED,     *MONEY_AMOUNT
  property LOAN_RECOVERY,        *MONEY_AMOUNT
  property :is_advance_adjusted, Boolean, :default => lambda {|obj, p| (obj.advance_adjusted > 0)}
  property :currency,            *CURRENCY
  property :performed_at,        *INTEGER_NOT_NULL
  property :accounted_at,        *INTEGER_NOT_NULL
  property :effective_on,        *DATE_NOT_NULL
  property :created_at,          *CREATED_AT

  belongs_to :lending
  belongs_to :payment_transaction, :nullable => true

  validates_with_method :not_all_amounts_are_zero

  def money_amounts
    [PRINCIPAL_RECEIVED, INTEREST_RECEIVED, ADVANCE_RECEIVED, ADVANCE_ADJUSTED, LOAN_RECOVERY]
  end

  # Record the principal, interest, and advance amounts received on a loan on the specified value date
  # @param [Hash] allocation_values such as {:principal_received => principal_received_money_obj, :interest_received => interest_received_money_obj, :advance_received => advance_received_money_obj}
  # @param [Lending] on_loan
  # @param [Date] effective_on
  def self.record_allocation_as_loan_receipt(payment_transaction, allocation_values, performed_at, accounted_at, on_loan, effective_on)
    Validators::Arguments.not_nil?(allocation_values, performed_at, accounted_at, on_loan, effective_on)
    receipt                     = Money.from_money(allocation_values)
    receipt.delete(TOTAL_RECEIVED)
    receipt[:payment_transaction_id] = payment_transaction.id
    receipt[:performed_at]           = performed_at
    receipt[:accounted_at]           = accounted_at
    receipt[:lending]                = on_loan
    receipt[:effective_on]           = effective_on
    loan_receipt                     = create(receipt)
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

  # Sum of all receipts upto and including the specified between dates
  def self.sum_between_dates(from_date = Date.today, to_date = Date.today)
    matching_date                    = { }
    matching_date[:effective_on.gte] = from_date
    matching_date[:effective_on.lte] = to_date
    all_receipts                     = all(matching_date)
    add_up(all_receipts)
  end

  def self.sum_till_date_for_loans(loans, to_date = Date.today)
    matching_date                    = { }
    matching_date[:lending_id]       = loans.class == Array ? loans.flatten : [loans]
    matching_date[:effective_on.lte] = to_date
    all_receipts                     = all(matching_date)
    add_up(all_receipts)
  end

  def self.sum_between_dates_for_loans(loans, from_date = Date.today, to_date = Date.today)
    matching_date                    = { }
    matching_date[:lending_id]       = loans.class == Array ? loans.flatten : [loans]
    matching_date[:effective_on.gte] = from_date
    matching_date[:effective_on.lte] = to_date
    all_receipts                     = all(matching_date)
    add_up(all_receipts)
  end

  def self.update_loan_receipts
    all_receipts = all(:payment_transaction_id => nil)
    all_receipts.each do |receipt|
      pt = PaymentTransaction.first(:payment_towards => Constants::Transaction::PAYMENT_TOWARDS_LOAN_REPAYMENT, :on_product_id => receipt.lending_id, :effective_on => receipt.effective_on, :accounted_at => receipt.accounted_at, :performed_at => receipt.performed_at)
      pt = PaymentTransaction.first(:payment_towards => Constants::Transaction::PAYMENT_TOWARDS_LOAN_PRECLOSURE, :on_product_id => receipt.lending_id, :effective_on => receipt.effective_on, :accounted_at => receipt.accounted_at, :performed_at => receipt.performed_at) if pt.blank?
      receipt.update(:payment_transaction_id => pt.id) unless pt.blank?
    end
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
    totals[LOAN_RECOVERY]      = zero_money

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

      all_loan_recovery_amounts = all_money_receipts.collect { |receipt| receipt[LOAN_RECOVERY] }
      totals[LOAN_RECOVERY] = all_loan_recovery_amounts.reduce(:+) unless all_loan_recovery_amounts.empty?
    end

    Money.add_total_to_map(totals, :total_received)
  end

end
