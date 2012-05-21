module MarkerInterfaces
  module LoanAmountsImpl

    # please refer Constants::LoanAmounts

    def total_loan_disbursed
      self.disbursed_amount || self.approved_amount || self.applied_amount
    end

    def total_interest_applicable
      #TODO
    end

    def total_principal_and_interest_applicable
      total_loan_disbursed + total_interest_applicable
    end

    def total_advance_accumulated
      #TODO
    end

    def total_advance_adjusted
      #TODO
    end

    def scheduled_principal_due(on_date)
      #TODO
    end

    def scheduled_interest_due(on_date)
      #TODO
    end

    def scheduled_total_due(on_date)
      scheduled_principal_due(on_date) + scheduled_interest_due(on_date)
    end

    def principal_overdue(on_date)
      #TODO
    end

    def interest_overdue(on_date)
      #TODO
    end

    def total_overdue(on_date)
      principal_overdue(on_date) + interest_overdue(on_date)
    end

    def principal_received(on_date)
      #TODO
    end

    def interest_received(on_date)
      #TODO
    end

    def advance_received(on_date)
      #TODO
    end

    def total_received(on_date)
      principal_received(on_date) + interest_received(on_date) + advance_received(on_date)
    end

    def advance_adjusted(on_date)
      #TODO
    end

    def principal_outstanding(on_date)
      #TODO
    end

    def principal_at_risk(on_date)
      #TODO
    end

  end
end