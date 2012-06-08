module BookKeeper

  def record_voucher(transaction_summary)
  	#the money category says what kind of transaction this is
  	raise ArgumentError, "Unable to resolve the money category for transaction summary: #{transaction_summary}" unless (transaction_summary and transaction_summary.money_category)
  	money_category = transaction_summary.money_category

  	#the voucher contents come from the transaction summary
  	total_amount, currency, effective_on = transaction_summary.amount, transaction_summary.currency, transaction_summary.effective_on
    notation = nil
  	
  	#the accounting rule is obtained from the money category
  	raise StandardError, "Unable to resolve the accounting rule corresponding to money category: #{money_category}" unless money_category.accounting_rule
  	accounting_rule = money_category.accounting_rule
  	postings = accounting_rule.get_posting_info(total_amount, currency) 
  	
  	#any applicable cost centers are resolved
  	branch_id = transaction_summary.branch_id
    raise StandardError, "no branch ID was available for the transaction summary" unless branch_id

    #record voucher
  	Voucher.create_generated_voucher(total_amount, currency, effective_on, postings, notation)
    transaction_summary.set_processed
  end

  def account_for_payment_transaction(payment_transaction)
    #TODO
  end

  def get_primary_chart_of_accounts
    AccountsChart.first
  end

  def setup_counterparty_accounts_chart(for_counterparty)
    AccountsChart.setup_counterparty_accounts_chart(for_counterparty)
  end

  def get_counterparty_accounts_chart(for_counterparty)
    AccountsChart.get_counterparty_accounts_chart(for_counterparty)
  end

  def get_ledger(by_ledger_id)
    Ledger.get(by_ledger_id)
  end

  def get_ledger_opening_balance_and_date(by_ledger_id)
    ledger = get_ledger(by_ledger_id)
    raise Errors::DataMissingError, "Unable to locate ledger by ID: #{by_ledger_id}" unless ledger
    ledger.opening_balance_and_date
  end

  def get_current_ledger_balance(by_ledger_id)
    get_historical_ledger_balance(by_ledger_id, Date.today)
  end

  def get_historical_ledger_balance(by_ledger_id, on_date)
    ledger = get_ledger(by_ledger_id)
    raise Errors::DataMissingError, "Unable to locate ledger by ID: #{by_ledger_id}" unless ledger
    ledger.balance(on_date)
  end

end

class MyBookKeeper
  include BookKeeper

  def initialize(at_time = DateTime.now)
    @created_at = at_time
  end

  def to_s 
    "#{self.class} created at #{@created_at}"
  end

end