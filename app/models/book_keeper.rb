module BookKeeper
  include Constants::LoanAmounts, Constants::Accounting, Constants::Products, Constants::Transaction

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

  def account_for_payment_transaction(payment_transaction, payment_allocation)
    # determine the product action
    product_action = payment_transaction.product_action
    raise Errors::InvalidConfigurationError, "Unable to determine the product action for the payment transaction" unless product_action

    total_amount, currency, effective_on = payment_transaction.amount, payment_transaction.currency, payment_transaction.effective_on
    notation = nil

    product_accounting_rule = ProductAccountingRule.resolve_rule_for_product_action(product_action)
    postings = product_accounting_rule.get_posting_info(payment_transaction, payment_allocation)
    Voucher.create_generated_voucher(total_amount, payment_transaction.receipt_type, currency, effective_on, postings, payment_transaction.performed_at, payment_transaction.accounted_at, notation)
  end

  def self.can_accrue_on_loan_on_date?(loan, on_date)
    loan.is_outstanding_on_date?(on_date) and
      (on_date >= loan.scheduled_first_repayment_date) and
      (on_date >  loan.disbursal_date_value)
  end

  def accrue_all_receipts_on_loan(loan, on_date)
    return unless BookKeeper.can_accrue_on_loan_on_date?(loan, on_date)
    if (loan.schedule_date?(on_date))
      # only accrue regular interest receipts for loans that are scheduled to repay on_date
      accrue_regular_receipts_on_loan(loan, on_date)
    elsif
      if (Constants::Time.is_last_day_of_month?(on_date))
        accrue_broken_period_interest_receipts_on_loan(loan, on_date)
      end
    end
    if (Constants::Time.is_first_day_of_month?(on_date))
      reverse_all_broken_period_interest_receipts(on_date)
    end
  end

  def accrue_all_receipts_on_loan_till_date(loan, till_date)
    loan_schedules = loan.schedule_dates.select{|date| date <= till_date}
    loan_schedules.each{|date| accrue_all_receipts_on_loan(loan, date)}
  end

  def accrue_regular_receipts_on_loan(loan, on_date)
    return unless BookKeeper.can_accrue_on_loan_on_date?(loan, on_date)
    amortization_on_date = loan.get_scheduled_amortization(on_date)
    amortization = amortization_on_date.values.first
    scheduled_principal_due = amortization[SCHEDULED_PRINCIPAL_DUE]
    scheduled_interest_due  = amortization[SCHEDULED_INTEREST_DUE]
    accrual_temporal_type = ACCRUE_REGULAR
    receipt_type = RECEIPT
    on_product_type, on_product_id = LENDING, loan.id
    by_counterparty_type, by_counterparty_id = Resolver.resolve_counterparty(loan.borrower)
    locations = LoanAdministration.get_locations(loan.id, on_date)
    raise ArgumentError, "Location is not defined on #{on_date} for Loan(#{loan.id})" if locations.blank?
    accounted_at = locations[:accounted_at].id
    performed_at = locations[:administered_at].id
    effective_on = on_date

    accrue_principal = AccrualTransaction.record_accrual(ACCRUE_PRINCIPAL_ALLOCATION, scheduled_principal_due, receipt_type, on_product_type, on_product_id, by_counterparty_type, by_counterparty_id, performed_at, accounted_at, effective_on, accrual_temporal_type)
    accrue_interest  = AccrualTransaction.record_accrual(ACCRUE_INTEREST_ALLOCATION, scheduled_interest_due, receipt_type, on_product_type, on_product_id, by_counterparty_type, by_counterparty_id, performed_at, accounted_at, effective_on, accrual_temporal_type)
  end

  def accrue_broken_period_interest_receipts_on_loan(loan, on_date)
    return unless BookKeeper.can_accrue_on_loan_on_date?(loan, on_date)
    broken_period_interest = loan.broken_period_interest_due(on_date)
    accrual_temporal_type = ACCRUE_BROKEN_PERIOD
    receipt_type = RECEIPT
    on_product_type, on_product_id = LENDING, loan.id
    by_counterparty_type, by_counterparty_id = Resolver.resolve_counterparty(loan.borrower)
    locations = LoanAdministration.get_locations(loan.id, on_date)
    raise ArgumentError, "Location is not defined on #{on_date} for Loan(#{loan.id})" if locations.blank?
    accounted_at = locations[:accounted_at].id
    performed_at = locations[:administered_at].id

    accrue_broken_period_interest_receipt = AccrualTransaction.record_accrual(ACCRUE_INTEREST_ALLOCATION, broken_period_interest, receipt_type, on_product_type, on_product_id, by_counterparty_type, by_counterparty_id, performed_at, accounted_at, effective_on, accrual_temporal_type)
  end

  def reverse_all_broken_period_interest_receipts(on_date)
    all_broken_period_interest_receipts_to_reverse = AccrualTransaction.all_broken_period_interest_accruals_not_reversed(on_date - 1)
    all_broken_period_interest_receipts_to_reverse.each { |bpial|
      reversal_accrual = bpial.to_reversed_broken_period_accrual
      raise Errors::DataError, reversal_accrual.errors.first.first unless reversal_accrual.save
      ReversedAccrualLog.record_reversed_accrual_log(bpial, reversal_accrual)
    }
  end

  def account_for_accrual(accrual_transaction)
    accrual_allocation = {:total_accrued => accrual_transaction.accrual_money_amount}
    account_for_payment_transaction(accrual_transaction, accrual_allocation)
  end

  def get_primary_chart_of_accounts
    AccountsChart.first(:name => 'Financial Accounting')
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
