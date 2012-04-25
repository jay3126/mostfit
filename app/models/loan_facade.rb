class LoanFacade < StandardFacade

  ##################
  ## QUERIES       #
  ##################

  def get_loans_at_location(location, on_date = Date.today)
    location.loans
  end

  def get_loan_frequencies_at_location(at_location, on_date = Date.today)
    all_loans_at_location = get_loans_at_location(at_location, on_date)
    loan_frequencies = all_loans_at_location.collect {|loan| loan.frequency}
    loan_frequencies.uniq
  end

end
