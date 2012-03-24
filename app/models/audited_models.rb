module Constants
  
  module Change
    
    MODELS_TO_BE_AUDITED = [
      Branch,
      Center,
      Client,
      ClientGroup,
      Loan,
      LoanProduct,
      User
    ]

    AUDIT_TRAIL_USER_NOT_FOUND = 'user not found'
    AUDIT_TRAIL_USER_ROLE_NOT_FOUND = 'user role not found'
    
  end

end
