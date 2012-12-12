module OverlapReportInterpreter
  include Constants::CreditBureau

  def rate_report

    reason_for_rejection = []

    # Member should not have more than 2 active loans-removed this condition
    # Now member can have any number of active loan but the total outstanding should not exceeds more than 50,000 Rs.
    # Member should not have relationship with other MFI
    total_loans_allowed = ConfigurationFacade.instance.regulation_total_loans_allowed
    reported_no_of_active_loans = self.respond_to?(:no_of_active_loans) ? self.no_of_active_loans : nil
    reported_no_of_mfis = self.respond_to?(:no_of_mfis) ? self.no_of_mfis : nil
    if reported_no_of_active_loans || reported_no_of_mfis
      reason_for_rejection << "Member have second active MFI relation" if (reported_no_of_mfis > 1)
    end

    # Member should not have Loan outstanding including our loan greater than 50,000, including applied loan amount
    loan_amount_applied_for = self.applied_for_amount
    raise StandardError, "Unable to determine the loan amount applied for" unless loan_amount_applied_for
    total_outstanding_allowed = ConfigurationFacade.instance.regulation_total_oustanding_allowed
    total_outstanding_money = MoneyManager.get_money_instance(self.total_outstanding)
    reported_total_outstanding = self.respond_to?(:total_outstanding) ? total_outstanding_money : nil
    if (reported_total_outstanding and loan_amount_applied_for)
      reason_for_rejection << "Member have loan outstanding including our loan is greater than 50000" if (reported_total_outstanding + loan_amount_applied_for) > total_outstanding_allowed
    end

    # Member should not have Overdue
    total_overdue_money = MoneyManager.get_money_instance(self.overdue_amount)
    total_scheduled_amount = MoneyManager.get_money_instance(self.scheduled_amount)

    reported_total_overdue = self.respond_to?(:overdue_amount) ? total_overdue_money : nil
    reported_total_scheduled_amount = self.respond_to?(:scheduled_amount) ? total_scheduled_amount : nil
    if reported_total_overdue || reported_total_scheduled_amount
      unless reported_total_overdue == MoneyManager.default_zero_money
        overdue_amount = (reported_total_overdue.amount.to_f)/100
        scheduled_amount = (total_scheduled_amount.amount.to_f)/100
        five_percent_of_scheduled_amount = ((scheduled_amount * 5).to_f)/100
        if overdue_amount > 10 && overdue_amount > five_percent_of_scheduled_amount
          reason_for_rejection << "Member have Overdues" 
        end
      end
    end

    reason_for_rejection.flatten.join(', ')
    
  end
    
end