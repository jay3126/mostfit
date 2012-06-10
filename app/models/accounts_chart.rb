class AccountsChart
  include DataMapper::Resource
  include Constants::Properties, Constants::Accounting, Constants::Transaction
  
  property :id,                Serial
  property :name,              *NAME
  property :guid,              *UNIQUE_ID
  property :chart_type,        Enum.send('[]', *ACCOUNTS_CHART_TYPES), :nullable => false
  property :counterparty_type, Enum.send('[]', *COUNTERPARTIES), :nullable => true
  property :counterparty_id,   Integer
  property :created_at,        *CREATED_AT

  has n, :ledgers
  has n, :ledger_assignments

  # Fetch the accounts chart for a counterparty for product accounting
  def self.get_counterparty_accounts_chart(for_counterparty)
    counterparty_type, counterparty_id = Resolver.resolve_counterparty(for_counterparty)
    chart_for_counterparty = {}
    chart_for_counterparty[:counterparty_type] = counterparty_type
    chart_for_counterparty[:counterparty_id]   = counterparty_id
    chart_for_counterparty[:chart_type]        = PRODUCT_ACCOUNTING
    first(chart_for_counterparty)
  end

  # Setup the accounts chart for a counterparty for product accounting
  def self.setup_counterparty_accounts_chart(for_counterparty)
    counterparty_type, counterparty_id = Resolver.resolve_counterparty(for_counterparty)
    chart_for_counterparty = {}
    chart_for_counterparty[:name]              = for_counterparty.name
    chart_for_counterparty[:counterparty_type] = counterparty_type
    chart_for_counterparty[:counterparty_id]   = counterparty_id
    chart_for_counterparty[:chart_type]        = PRODUCT_ACCOUNTING
    accounts_chart = first_or_create(chart_for_counterparty)
    raise Errors::DataError, accounts_chart.errors.first.first unless accounts_chart.id
    accounts_chart
  end

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
