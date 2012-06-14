module Constants
  module LoanAssignment

  NOT_ASSIGNED = :not_assigned; ASSIGNED = :assigned
  LOAN_ASSIGNMENT_STATUSES = [NOT_ASSIGNED, ASSIGNED]

  SECURITISED = :securitised; ENCUMBERED = :encumbered
  LOAN_ASSIGNMENT_NATURE = [SECURITISED, ENCUMBERED]

  ASSIGNMENT_AND_MODELS = {
  	SECURITISED => 'Securitization',
  	ENCUMBERED  => 'Encumberance'
  }

  MODELS_AND_ASSIGNMENTS = {
  	'Securitization' => SECURITISED, 'Encumberance' => ENCUMBERED
  }

  end
end
