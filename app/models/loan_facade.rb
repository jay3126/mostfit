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

  def scheduled_principal_and_interest_due(on_loan_id, on_date = Date.today)
    @loan_manager.scheduled_principal_and_interest_due(on_loan_id, on_date)
  end

  ################
  # ALL RECEIPTS # on a specific loan begins
  ################

  def amounts_received_on_date(on_loan_id, on_date = Date.today)
    @loan_manager.amounts_received_on_date(on_loan_id, on_date)
  end

  def principal_received_on_date(on_loan_id, on_date = Date.today)
    @loan_manager.principal_received_on_date(on_loan_id, on_date)
  end

  def interest_received_on_date(on_loan_id, on_date = Date.today)
    @loan_manager.interest_received_on_date(on_loan_id, on_date)
  end

  def advance_received_on_date(on_loan_id, on_date = Date.today)
    @loan_manager.advance_received_on_date(on_loan_id, on_date)
  end

  def amounts_received_till_date(on_loan_id, on_or_before_date = Date.today)
    @loan_manager.amounts_received_till_date(on_loan_id, on_or_before_date)
  end

  def principal_received_till_date(on_loan_id, on_or_before_date = Date.today)
    @loan_manager.principal_received_till_date(on_loan_id, on_or_before_date)
  end

  def interest_received_till_date(on_loan_id, on_or_before_date = Date.today)
    @loan_manager.interest_received_till_date(on_loan_id, on_or_before_date)
  end

  def advance_received_till_date(on_loan_id, on_or_before_date = Date.today)
    @loan_manager.advance_received_till_date(on_loan_id, on_or_before_date)
  end

  ################
  # ALL RECEIPTS # on a specific loan ends
  ################

  def get_loans_administered(at_location, on_date = Date.today)
    #TODO
  end

  def get_loans_accounted(at_location, on_date = Date.today)
    #TODO
  end

  # UPDATES

  def account_for_payment(payment_transaction, on_loan_id, with_loan_action)
    #TBD
  end

  private

  # LoanManager instance
  def loan_manager; @loan_manager ||= LoanManager.new; end

end
