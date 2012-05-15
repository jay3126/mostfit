class AccountsChart
  include DataMapper::Resource
  include Constants::Properties, Constants::Accounting
  
  property :id,         Serial
  property :name,       *UNIQUE_NAME
  property :guid,       *UNIQUE_ID
  property :chart_type, Enum.send('[]', *ACCOUNTS_CHART_TYPES), :nullable => false

  has n, :ledgers

  # Computes the sum of balances on all ledgers on this accounts chart as on_date
  def compute_sum_of_balances(on_date = Date.today)
    currency_in_use = self.ledgers.first.balance(on_date).currency
    zero_balance = LedgerBalance.zero_debit_balance(currency_in_use)
    self.ledgers.inject(zero_balance) { |sum, ledger| sum + ledger.balance(on_date) }
  end

  # Tests whether the accounts chart is "balanced" on the specified date
  def is_balanced?(on_date = Date.today)
    sum = compute_sum_of_balances(on_date)
    LedgerBalance.is_zero_balance?(sum)
  end

end
