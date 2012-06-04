module Validators

  module Arguments

    # Validates that none of the arguments are nil
    def self.not_nil?(*arg)
      arg.each { |argument|
        raise ArgumentError, "#{argument} is null" if argument.nil?
      }
      true
    end

  end

  module Amounts

    # Validates that none of the arguments are nil or negative
    def self.is_positive?(*amount)
      amount.each { |amt|
        raise ArgumentError, "amount is not specified" unless amt
        raise ArgumentError, "amount is not a number" unless amt.is_a?(Numeric)
        raise ArgumentError, "amount: #{amt} is negative" if amt < 0
      }
      true
    end

  end

  module Amortization

    # Checks the amortization by tenure, the total amounts of principal and interest, and the amortization schedule for principal and for interest
    def self.is_valid_amortization?(tenure, total_loan_disbursed, total_interest_applicable, principal_amounts, interest_amounts)
      raise Errors::BusinessValidationError, "Tenure should be a positive number" unless tenure > 0
      raise Errors::BusinessValidationError, "Principal repayments do not equal tenure in number" unless principal_amounts.length == tenure
      raise Errors::BusinessValidationError, "Interest repayments do not equal tenure in number" unless interest_amounts.length == tenure
      zero_money_amount = MoneyManager.default_zero_money
      calculated_total_principal_amount = principal_amounts.inject(zero_money_amount) {|sum, principal| sum + principal}
      raise Errors::BusinessValidationError, "Principal repayments do not add up to total loan disbursed" unless calculated_total_principal_amount == total_loan_disbursed
      calculated_total_interest_amount = interest_amounts.inject(zero_money_amount) {|sum, interest| sum + interest}
      raise Errors::BusinessValidationError, "Interest repayments do not add up to total interest applicable" unless calculated_total_interest_amount == total_interest_applicable
      true
    end

  end

end
