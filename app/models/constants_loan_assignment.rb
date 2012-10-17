module Constants
  module LoanAssignment

    NOT_ASSIGNED = :not_assigned; ASSIGNED = :assigned
    LOAN_ASSIGNMENT_STATUSES = [NOT_ASSIGNED, ASSIGNED]

    SECURITISED = :securitised; ENCUMBERED = :encumbered; ADDITIONAL_ENCUMBRED = :additional_encumbered
    LOAN_ASSIGNMENT_NATURE = [SECURITISED, ENCUMBERED]

    ASSIGNMENT_AND_MODELS = {
      SECURITISED => 'Securitization',
      ENCUMBERED  => 'Encumberance'
    }

    MODELS_AND_ASSIGNMENTS = {
      'Securitization' => SECURITISED, 'Encumberance' => ENCUMBERED, 'AdditionalEncumbrance' => ADDITIONAL_ENCUMBRED
    }

  end
end
