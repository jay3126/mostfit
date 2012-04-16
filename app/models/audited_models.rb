module Constants
  
  module Change
    
    MODELS_TO_BE_AUDITED = [
      Account, #TO BE REMOVED
      ApplicableFee,
      Area,
      AssetRegister,
      Attendance,
      AuditItem,
      Branch,
      BranchDiary,
      Center,
      CenterLeader,
      CenterMeetingDay, #TO BE REMOVED
      Cgt,
      Claim,
      Client,
      ClientGroup,
      ClientType,
      Comment,
      CreditAccountRule, #TO BE REMOVED
      DebitAccountRule, #TO BE REMOVED
      Document,
      DocumentType,
      Domain,
      Fee,
      Funder,
      FundingLine,
      Grt,
      Guarantor,
      Holiday, #TO BE REMOVED
      HolidayCalendar, #TO BE REMOVED
      HolidaysFor, #TO BE REMOVED
      InsuranceCompany,
      InsurancePolicy,
      InsuranceProduct,
      Journal, #TO BE REMOVED
      JournalType, #TO BE REMOVED
      Loan,
      LoanProduct,
      LoanPurpose,
      LoanType,
      LoanUtilization,
      Location,
      Mfi,
      Occupation,
      Organization,
      Payment,
      Portfolio,
      PortfolioLoan,
      Posting, #TO BE REMOVED
      Region,
      RepaymentStyle,
      ReversedJournalLog, #TO BE REMOVED
      Rule, #TO BE REMOVED
      RuleBook, #TO BE REMOVED
      StaffMember,
      StaffMemberAttendance,
      StockRegister,
      Target,
      Upload,
      User
    ]

    AUDIT_TRAIL_USER_NOT_FOUND = 'user not found'
    AUDIT_TRAIL_USER_ROLE_NOT_FOUND = 'user role not found'
    
  end

end