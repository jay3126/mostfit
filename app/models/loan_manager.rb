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

  def allocate_payment(payment_transaction, on_loan_id, with_loan_action)
    get_loan(on_loan_id).allocate_payment(payment_transaction, with_loan_action)
  end

end
