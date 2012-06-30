module Constants
  module Insurance

    INSURED_CLIENT = :insured_client; INSURED_SPOUSE = :insured_spouse; INSURED_GUARANTOR = :insured_guarantor
    INSURED_CLIENT_AND_SPOUSE = :insured_client_and_spouse; INSURED_CLIENT_AND_GUARANTOR = :insured_client_and_guarantor

    INSURED_PERSON_RELATIONSHIPS = [INSURED_CLIENT, INSURED_SPOUSE, INSURED_GUARANTOR, INSURED_CLIENT_AND_SPOUSE, INSURED_CLIENT_AND_GUARANTOR]

  end
end
