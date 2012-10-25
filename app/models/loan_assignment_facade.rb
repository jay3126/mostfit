class LoanAssignmentFacade < StandardFacade
  include Constants::LoanAssignment

  ###########
  # QUERIES #
  ###########

  def get_loan_assignment_status(for_loan_id, on_date)
    LoanAssignment.get_loan_assignment_status(for_loan_id, on_date)
  end

  def get_loan_assigned_to(for_loan_id, on_date)
    LoanAssignment.get_loan_assigned_to(for_loan_id, on_date)
  end

  def get_loans_assigned(to_loan_assignment, on_date)
    LoanAssignment.get_loans_assigned(to_loan_assignment, on_date)
  end

  def get_loans_assigned_in_date_range(to_loan_assignment, on_date, till_date)
    LoanAssignment.get_loans_assigned_in_date_range(to_loan_assignment, on_date, till_date)
  end

  def get_loans_assigned_to_tranch(to_tranch)
    LoanAssignment.get_loans_assigned_to_tranch(to_tranch)
  end

  def get_loan_information(for_loan_id)
    #TODO
  end

  def get_loan_status(for_loan_id)
    #TODO
  end

  ###########
  # UPDATES #
  ###########

  def assign(loan_id, to_assignment)
    LoanAssignment.assign(loan_id, to_assignment, for_user.id)
  end
  
  def assign_on_date(loan_id, assignment_nature, on_date, funder_id, funding_line_id, tranch_id, additional_encumbered = false)
    LoanAssignment.assign_on_date(loan_id, assignment_nature, on_date, funder_id, funding_line_id, tranch_id, for_user.id, additional_encumbered)
  end

  def assign_to_tranch_on_date(loan_id, to_tranch, on_date)
    FundsSource.assign_to_tranch_on_date(loan_id, to_tranch, on_date)
  end

  def create_securitization(by_name, effective_on, for_third_parties, performed_by, for_user)
    #TODO
  end

  def create_encumberance(by_name, effective_on, assigned_value)
    Encumberance.create_encumberance(by_name, effective_on, assigned_value)
  end

  def find_assignment_by_type_and_name(by_type, for_name)
    case by_type
    when SECURITISED then return get_securitization(:name => for_name)
    when ENCUMBERED  then return get_encumberance(:name => for_name)
    else
      raise ArgumentError, "The assignment type #{by_type} is not recognized"
    end
  end

  def get_encumberance(search_options = {})
    Encumberance.first(search_options)
  end

  def list_encumberances(search_options = {})
    Encumberance.all(search_options)
  end

  def get_securitization(search_options = {})
    Securitization.first(search_options)
  end

  def list_securitization(search_options = {})
    Securitization.all(search_options)
  end

  def loan_assignment_status_message(loan_id, on_date = Date.today)
    LoanAssignment.loan_assignment_status_message(loan_id, on_date)
  end

end