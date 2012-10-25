class ProductPostingRule
  include DataMapper::Resource
  include Constants::Accounting

  property :id,             Serial
  property :product_amount, Enum.send('[]', *PRODUCT_AMOUNTS), :nullable => false
  property :effect,         Enum.send('[]', *ACCOUNTING_EFFECTS), :nullable => false

  belongs_to :ledger_classification
  belongs_to :product_accounting_rule

  def to_posting_info(payment_transaction, payment_allocation)
    posting_money_amount = payment_allocation[self.product_amount]
    raise ArgumentError, "Did not find an amount for #{self.product_amount} in the allocation: #{payment_allocation}" unless posting_money_amount
    counterparty_type, counterparty_id = payment_transaction.by_counterparty_type, payment_transaction.by_counterparty_id

    product_type, product_id = self.ledger_classification.is_product_specific ?  [payment_transaction.on_product_type, payment_transaction.on_product_id] :
      [nil, nil]

    ledger = LedgerAssignment.locate_ledger(counterparty_type, counterparty_id, self.ledger_classification, product_type, product_id)
    raise Errors::InvalidConfigurationError, "Unable to locate the product accounting ledger" unless ledger
    PostingInfo.new(posting_money_amount.amount, posting_money_amount.currency, self.effect, ledger, payment_transaction.accounted_at, payment_transaction.performed_at)
  end

  def to_location_posting_info(payment_allocation, location_id, on_date = Date.today)
    posting_money_amount = payment_allocation[self.product_amount]
    location_ledgers = AccountingLocation.all(:effective_on.gte => on_date, :product_type => 'ledger', :biz_location_id => location_id).map(&:product).compact
    ledgers = location_ledgers.select{|l| l.ledger_classification == self.ledger_classification}
    raise Errors::InvalidConfigurationError, "Unable to locate the product accounting ledger" if ledgers.blank?
    PostingInfo.new(posting_money_amount.amount, posting_money_amount.currency, self.effect, ledgers.first, location_id, nil)
  end

  def to_due_generation_posting_info(payment_allocation, accounted_id, performed_id, loan_id, client_id, on_date = Date.today)
    posting_money_amount = payment_allocation[self.product_amount]
    ledger = LedgerAssignment.locate_ledger('client', client_id, self.ledger_classification, 'lending', loan_id)
    raise Errors::InvalidConfigurationError, "Unable to locate the product accounting ledger" if ledger.blank?
    PostingInfo.new(posting_money_amount.amount, posting_money_amount.currency, self.effect, ledger, accounted_id, performed_id)
  end
end

# A payment is made on a product
# The payment has an allocation that is several of principal receipt, interest receipt, advance receipt, advance adjusted, fee, or disbursement
# For each kind of payment, there is an effect on a corresponding ledger classification
# Each allocation goes to a ledger classification, and a ledger for that ledger classification must be located for the counterparty for the product
