module OverlapReportInterpreter
  include Constants::CreditBureau

  def rate_report
    total_loans_allowed = ConfigurationFacade.instance.regulation_total_loans_allowed
    reported_no_of_active_loans = self.respond_to?(:no_of_active_loans) ? self.no_of_active_loans : nil
    if reported_no_of_active_loans
      return RATED_NEGATIVE if (reported_no_of_active_loans + 1) > total_loans_allowed
    end

    loan_amount_applied_for = self.respond_to?(:applied_for_amount) ? self.applied_for_amount : nil
    raise StandardError, "Unable to determine the loan amount applied for" unless loan_amount_applied_for

    total_outstanding_allowed = ConfigurationFacade.instance.regulation_total_oustanding_allowed
    reported_total_outstanding = self.respond_to?(:total_outstanding) ? self.total_outstanding : nil
    if (reported_total_outstanding and loan_amount_applied_for)
      return RATED_NEGATIVE if (reported_total_outstanding + loan_amount_applied_for) > total_outstanding_allowed
    end

    RATED_POSITIVE
  end
    
end