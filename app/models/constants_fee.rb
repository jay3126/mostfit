module Constants
  module Fee

    FEE_ON_CLIENT    = :fee_on_client
    FEE_ON_LOAN      = :fee_on_loan
    FEE_ON_INSURANCE = :fee_on_insurance
    
    FEE_APPLIED_ON_TYPES = [FEE_ON_CLIENT, FEE_ON_LOAN, FEE_ON_INSURANCE]

    FEE_APPLIED_ON_TYPES_AND_MODELS = {
      FEE_ON_CLIENT    => 'Client',
      FEE_ON_LOAN      => 'Lending',
      FEE_ON_INSURANCE => 'SimpleInsurancePolicy'
    }

    MODELS_AND_FEE_APPLIED_ON_TYPES = {
      'Client'                => FEE_ON_CLIENT,
      'Lending'               => FEE_ON_LOAN,
      'SimpleInsurancePolicy' => FEE_ON_INSURANCE
    }

  end
end