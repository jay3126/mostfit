class LoanManager

  # The LoanManager intermediates on operations across one or more loans

  def get_loan(for_loan_id)
    Lending.get(for_loan_id) or raise Errors::DataMissingError, "Unable to locate loan with id: #{for_loan_id}"
  end

  def get_total_loan_disbursed(for_loan_id)
    get_loan(for_loan_id).total_loan_disbursed
  end

  def get_total_interest_applicable(for_loan_id)
    get_loan(for_loan_id).total_interest_applicable
  end

  def get_current_loan_status(for_loan_id)
    get_loan(for_loan_id).current_loan_status
  end

  def get_historical_loan_status_on_date(for_loan_id, on_date)
    get_loan(for_loan_id).historical_loan_status_on_date(on_date)
  end

  def get_current_loan_due_status(for_loan_id)
    get_loan(for_loan_id).current_due_status
  end

  def get_historical_loan_due_status_on_date(for_loan_id, on_date)
    get_loan(for_loan_id).historical_due_status_on_date(on_date)
  end

  def get_current_days_past_due(for_loan_id)
    get_loan(for_loan_id).days_past_due
  end

  def get_days_past_due_on_date(for_loan_id, on_date)
    get_loan(for_loan_id).days_past_due_on_date(on_date)
  end

  def previous_and_current_schedule_dates(for_loan_id, on_date)
    get_loan(for_loan_id).previous_and_current_schedule_dates(on_date)
  end

  def scheduled_principal_and_interest_due(on_loan_id, on_date)
    get_loan(on_loan_id).scheduled_principal_and_interest_due(on_date)
  end

  def previous_and_current_amortization_items(on_loan_id, on_date)
    get_loan(on_loan_id).previous_and_current_amortization_items(on_date)
  end

  def amounts_received_on_date(on_loan_id, on_date)
    get_loan(on_loan_id).amounts_received_on_date(on_date)
  end

  def principal_received_on_date(on_loan_id, on_date)
    get_loan(on_loan_id).principal_received_on_date(on_date)
  end

  def interest_received_on_date(on_loan_id, on_date)
    get_loan(on_loan_id).interest_received_on_date(on_date)
  end

  def advance_received_on_date(on_loan_id, on_date)
    get_loan(on_loan_id).advance_received_on_date(on_date)
  end

  def amounts_received_till_date(on_loan_id)
    get_loan(on_loan_id).amounts_received_till_date
  end

  def historical_amounts_received_till_date(on_loan_id, on_or_before_date)
    get_loan(on_loan_id).historical_amounts_received_till_date(on_or_before_date)
  end

  def principal_received_till_date(on_loan_id)
    get_loan(on_loan_id).principal_received_till_date
  end

  def interest_received_till_date(on_loan_id)
    get_loan(on_loan_id).interest_received_till_date
  end

  def advance_received_till_date(on_loan_id)
    get_loan(on_loan_id).advance_received_till_date
  end

  # transactions

  def is_payment_permitted?(payment_transaction)
    payment_on_loan = payment_transaction.on_product_instance
    raise ArgumentError, "Payment transaction is not on loan" unless payment_on_loan.is_a?(Lending)
    payment_on_loan.is_payment_permitted?(payment_transaction)
  end

  def allocate_payment(payment_transaction, on_loan_id, with_loan_action, make_specific_allocation, specific_principal_money_amount, specific_interest_money_amount, fee_instance_id, adjust_complete_advance =false)
    get_loan(on_loan_id).allocate_payment(payment_transaction, with_loan_action, make_specific_allocation, specific_principal_money_amount, specific_interest_money_amount, fee_instance_id, adjust_complete_advance)
  end

  def adjust_advance(on_date, on_loan_id, performed_by_id, using_payment_facade)
    loan = get_loan(on_loan_id)

    is_schedule_date = loan.schedule_date?(on_date)
    raise Errors::BusinessValidationError, "Advance cannot be adjusted on date: #{on_date} as the same is not a schedule date for the loan" unless is_schedule_date

    _advance_balance = loan.advance_balance(on_date)
    raise Errors::BusinessValidationError, "Advance balance is not available on the loan on the date: #{on_date}" unless (_advance_balance > loan.zero_money_amount)
    _actual_total_due = loan.actual_total_due_ignoring_advance_balance(on_date)

    money_amount = [_advance_balance, _actual_total_due].min
    if money_amount > MoneyManager.default_zero_money
      receipt_type = Constants::Transaction::CONTRA
      payment_towards = Constants::Transaction::PAYMENT_TOWARDS_LOAN_ADVANCE_ADJUSTMENT
      on_product_type = Constants::Products::LENDING
      on_product_id   = on_loan_id
      by_counterparty_type, by_counterparty_id = Resolver.resolve_counterparty(loan.borrower)
      performed_at = (loan.administered_at(on_date)).id
      accounted_at = (loan.accounted_at(on_date)).id
      performed_by = performed_by_id
      effective_on = on_date
      product_action = Constants::Transaction::LOAN_ADVANCE_ADJUSTMENT

      using_payment_facade.record_payment(money_amount, receipt_type, payment_towards, '', on_product_type, on_product_id, by_counterparty_type, by_counterparty_id, performed_at, accounted_at, performed_by, effective_on, product_action)
    end
  end

  def adjust_advance_for_perclose(on_date, on_loan_id, performed_by_id, using_payment_facade)
    loan = get_loan(on_loan_id)
    advance_balance = loan.current_advance_available
    raise Errors::BusinessValidationError, "Advance balance is not available on the loan on the date: #{on_date}" unless (advance_balance > loan.zero_money_amount)

    receipt_type = Constants::Transaction::CONTRA
    payment_towards = Constants::Transaction::PAYMENT_TOWARDS_LOAN_ADVANCE_ADJUSTMENT
    on_product_type = Constants::Products::LENDING
    on_product_id   = on_loan_id
    by_counterparty_type, by_counterparty_id = Resolver.resolve_counterparty(loan.borrower)
    performed_at = (loan.administered_at(on_date)).id
    accounted_at = (loan.accounted_at(on_date)).id
    performed_by = performed_by_id
    effective_on = on_date
    product_action = Constants::Transaction::LOAN_ADVANCE_ADJUSTMENT

    using_payment_facade.record_adjust_advance_payment(advance_balance, receipt_type, payment_towards, '',on_product_type, on_product_id, by_counterparty_type, by_counterparty_id, performed_at, accounted_at, performed_by, effective_on, product_action, true)
  end
end
