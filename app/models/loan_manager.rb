class LoanManager

  # The LoanManager intermediates on operations across one or more loans

  def scheduled_principal_and_interest_due(on_loan_id, on_date = Date.today)
    loan = Lending.get(on_loan_id)
    raise Errors::DataMissingError, "Unable to locate loan with id: #{on_loan_id}" unless loan
    loan.scheduled_principal_and_interest_due(on_date)
  end

  def amounts_received_on_date(on_loan_id, on_date = Date.today)
    loan = Lending.get(on_loan_id)
    raise Errors::DataMissingError, "Unable to locate loan with id: #{on_loan_id}" unless loan
    loan.amounts_received_on_date(on_loan_id, on_date)
  end

  def principal_received_on_date(on_loan_id, on_date = Date.today)
    loan = Lending.get(on_loan_id)
    raise Errors::DataMissingError, "Unable to locate loan with id: #{on_loan_id}" unless loan
    loan.principal_received_on_date(on_loan_id, on_date)
  end

  def interest_received_on_date(on_loan_id, on_date = Date.today)
    loan = Lending.get(on_loan_id)
    raise Errors::DataMissingError, "Unable to locate loan with id: #{on_loan_id}" unless loan
    loan.interest_received_on_date(on_loan_id, on_date)
  end

  def advance_received_on_date(on_loan_id, on_date = Date.today)
    loan = Lending.get(on_loan_id)
    raise Errors::DataMissingError, "Unable to locate loan with id: #{on_loan_id}" unless loan
    loan.advance_received_on_date(on_loan_id, on_date)
  end

  def amounts_received_till_date(on_loan_id, on_or_before_date = Date.today)
    loan = Lending.get(on_loan_id)
    raise Errors::DataMissingError, "Unable to locate loan with id: #{on_loan_id}" unless loan
    loan.amounts_received_till_date(on_loan_id, on_or_before_date)
  end

  def principal_received_till_date(on_loan_id, on_or_before_date = Date.today)
    loan = Lending.get(on_loan_id)
    raise Errors::DataMissingError, "Unable to locate loan with id: #{on_loan_id}" unless loan
    loan.principal_received_till_date(on_loan_id, on_or_before_date)
  end

  def interest_received_till_date(on_loan_id, on_or_before_date = Date.today)
    loan = Lending.get(on_loan_id)
    raise Errors::DataMissingError, "Unable to locate loan with id: #{on_loan_id}" unless loan
    loan.interest_received_till_date(on_loan_id, on_or_before_date)
  end

  def advance_received_till_date(on_loan_id, on_or_before_date = Date.today)
    loan = Lending.get(on_loan_id)
    raise Errors::DataMissingError, "Unable to locate loan with id: #{on_loan_id}" unless loan
    loan.advance_received_till_date(on_loan_id, on_or_before_date)
  end

end
