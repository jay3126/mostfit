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

  # Obtain the loan balances for the loan as on a specified date
  # @param [Lending] on_loan
  # @param [Date] on_date
  def get_loan_balances(on_loan, on_date = Date.today)
    #TBD
  end

  # UPDATES

  def account_for_payment(payment_transaction, on_loan_id, with_loan_action)
    #TBD
  end

  def get_money_instance(*regular_amount_str)
    MoneyManager.get_money_instance(*regular_amount_str)
  end
end
