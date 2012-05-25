class LoanFacade < StandardFacade

  # QUERIES

  def get_loans_at_location(location, on_date = Date.today)
    location.loans
  end

  def get_loan_frequencies_at_location(at_location, on_date = Date.today)
    all_loans_at_location = get_loans_at_location(at_location, on_date)
    loan_frequencies = all_loans_at_location.collect {|loan| loan.frequency}
    loan_frequencies.uniq
  end

  ############################################
  # Loan administered and registered locations on a specific loan begins
  ############################################

  def get_loan_administered_at_location(loan_id, on_date = Date.today)
    LoanAdministration.get_administered_at(loan_id, on_date)
  end

  def get_loan_accounted_at_location(loan_id, on_date = Date.today)
    LoanAdministration.get_accounted_at(loan_id, on_date)
  end

  def get_loan_locations(loan_id, on_date = Date.today)
    LoanAdministration.get_locations(loan_id, on_date)
  end

  ############################################
  # Loan administered and registered locations on a specific loan ends
  ############################################

  ##################
  # Loan information on a specific loan begins
  ##################

  def get_loan(loan_id)
    loan_manager.get_loan(loan_id)
  end

  def get_current_loan_status(for_loan_id)
    loan_manager.get_current_loan_status(for_loan_id)
  end

  def get_loan_status_on_date(for_loan_id, on_date)
    loan_manager.get_loan_status_on_date(for_loan_id, on_date)
  end

  def get_current_loan_due_status(for_loan_id)
    loan_manager.get_current_loan_due_status(for_loan_id)
  end

  def get_loan_due_status_on_date(for_loan_id, on_date)
    loan_manager.get_loan_due_status_on_date(for_loan_id, on_date)
  end

  def get_current_days_past_due(for_loan_id)
    loan_manager.get_current_days_past_due(for_loan_id)
  end

  def get_days_past_due_on_date(for_loan_id, on_date)
    loan_manager.get_days_past_due_on_date(for_loan_id, on_date)
  end

  ##################
  # Loan information on a specific loan ends
  ##################

  ######################
  # Loan scheduled dates on a specific loan begins
  ######################

  def get_previous_and_current_loan_schedule_dates(for_loan_id, on_date)
    loan_manager.previous_and_current_schedule_dates(for_loan_id, on_date)
  end

  ######################
  # Loan scheduled dates on a specific loan ends
  ######################

  #########################
  # Loan due and balances # on a specific loan begins
  #########################

  def scheduled_principal_and_interest_due(on_loan_id, on_date = Date.today)
    loan_manager.scheduled_principal_and_interest_due(on_loan_id, on_date)
  end

  #########################
  # Loan due and balances # on a specific loan ends
  #########################

  ###############
  # ALL RECEIPTS  on a specific loan begins
  ###############

  def amounts_received_on_date(on_loan_id, on_date = Date.today)
    loan_manager.amounts_received_on_date(on_loan_id, on_date)
  end

  def principal_received_on_date(on_loan_id, on_date = Date.today)
    loan_manager.principal_received_on_date(on_loan_id, on_date)
  end

  def interest_received_on_date(on_loan_id, on_date = Date.today)
    loan_manager.interest_received_on_date(on_loan_id, on_date)
  end

  def advance_received_on_date(on_loan_id, on_date = Date.today)
    loan_manager.advance_received_on_date(on_loan_id, on_date)
  end

  def amounts_received_till_date(on_loan_id, on_or_before_date = Date.today)
    loan_manager.amounts_received_till_date(on_loan_id, on_or_before_date)
  end

  def principal_received_till_date(on_loan_id, on_or_before_date = Date.today)
    loan_manager.principal_received_till_date(on_loan_id, on_or_before_date)
  end

  def interest_received_till_date(on_loan_id, on_or_before_date = Date.today)
    loan_manager.interest_received_till_date(on_loan_id, on_or_before_date)
  end

  def advance_received_till_date(on_loan_id, on_or_before_date = Date.today)
    loan_manager.advance_received_till_date(on_loan_id, on_or_before_date)
  end

  ################
  # ALL RECEIPTS # on a specific loan ends
  ################

  # UPDATES

  def account_for_payment(payment_transaction, on_loan_id, with_loan_action)
    #TBD
  end

  def assign_locations_for_loan(administered_at, accounted_at, to_loan, performed_by, recorded_by, effective_clon = Date.today)
    LoanAdministration.assign(administered_at, accounted_at, to_loan, performed_by, recorded_by, effective_on)
  end

  private

  # LoanManager instance
  def loan_manager; @loan_manager ||= LoanManager.new; end

end