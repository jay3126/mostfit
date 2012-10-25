module Allocation

  # Namespace for modules that implement commonly-used practices of allocation to
  # principal and interest across installments

  module Common

    # All instances must respond_to :currency

    def netoff_allocation(allocation, against_due_amounts_val)
      raise TypeError, "A value of currency is needed for money calculations and is not available" unless (respond_to?(:currency) and currency)
      zero_money = Money.zero_money_amount(currency)

      against_due_amounts = against_due_amounts_val.is_a?(Hash) ? against_due_amounts_val : amortization_to_due_amounts(against_due_amounts_val)

      total_principal_amount = allocation[:principal]
      total_interest_amount = allocation[:interest]

      installment_counter = 0
      running_principal_sum = zero_money; running_interest_sum = zero_money
      begin_with_interest = zero_money; begin_with_principal = zero_money

      against_due_amounts.keys.sort.each { |installment|
        installment_counter = installment
        installment_interest_amount = against_due_amounts[installment][:interest]
        running_interest_sum += installment_interest_amount
        does_interest_exceed = running_interest_sum >= total_interest_amount

        installment_principal_amount = against_due_amounts[installment][:principal]
        running_principal_sum += installment_principal_amount
        does_principal_exceed = running_principal_sum > total_principal_amount

        # invariant: it must stop with a particular installment
        must_stop_now = (does_interest_exceed or does_principal_exceed)
        if must_stop_now
          begin_with_interest = running_interest_sum - total_interest_amount
          begin_with_principal = running_principal_sum - total_principal_amount
          break
        end
      }

      netted_due_amounts = {}
      netted_due_amounts[1] = {:principal => begin_with_principal, :interest => begin_with_interest}
      netted_due_amounts_index = 1
      (installment_counter + 1).upto(against_due_amounts.keys.sort.last).each { |installment|
        netted_due_amounts_index += 1
        netted_due_amounts[netted_due_amounts_index] = against_due_amounts[installment]
      }
      netted_due_amounts
    end

    # Given a series of installments, this returns a data structure that has the
    # total principal amount and total interest amount
    # Data structure is as follows for due amounts
    # amounts = { 1 => {:principal => 100_Money, :interest => 20_Money}, 2 => {:principal => 110_Money, :interest => 10_Money} }
    def total_principal_and_interest(due_amounts)
      raise TypeError, "A value of currency is needed for money calculations and is not available" unless (respond_to?(:currency) and currency)
      zero_money = Money.zero_money_amount(currency)
      installments = due_amounts.keys
      total_principal, total_interest = zero_money, zero_money
      installments.each { |inst|
        total_principal += due_amounts[inst][:principal]
        total_interest += due_amounts[inst][:interest]
      }
      {:principal => total_principal, :interest => total_interest}
    end

    # Converts a data structure that is an array and has :scheduled_principal_due and :scheduled_interest_due as keys
    # to the expected amounts data structure
    def amortization_to_due_amounts(amortization)
      due_amounts = {}
      amortization.each { |item|
        installment = item.keys.first.first
        amounts = item[item.keys.first]
        due_amounts[installment] = remap(amounts)
      }
      due_amounts
    end

    def remap(amounts)
      principal_amount = amounts[Constants::LoanAmounts::SCHEDULED_PRINCIPAL_DUE]
      interest_amount = amounts[Constants::LoanAmounts::SCHEDULED_INTEREST_DUE]
      {:principal => principal_amount, :interest => interest_amount}
    end

    def self.calculate_broken_period_interest(ios_earlier, ios_later, prior_period_date, later_period_date, period_ends, loan_repayment_frequency)
      raise ArgumentError, "Dates: #{prior_period_date}, #{period_ends}, #{later_period_date} appear to be invalid for computing broken period interest" unless ((prior_period_date < period_ends) and (period_ends < later_period_date))
      total_number_of_days = 0
      if (loan_repayment_frequency == MarkerInterfaces::Recurrence::MONTHLY)
        total_number_of_days = (later_period_date - prior_period_date) + 1
      else
        total_number_of_days = MarkerInterfaces::Recurrence::FREQUENCIES_AS_PSEUDO_DAYS[loan_repayment_frequency]
      end
      raise Errors::BusinessValidationError, "Unable to determine the number of days between scheduled repayment dates" unless (total_number_of_days > 0)

      interim_interest = ios_earlier > ios_later ? (ios_earlier - ios_later) : (ios_later - ios_earlier)
      fractional_days_left = (period_ends - prior_period_date)/total_number_of_days
      interim_interest * fractional_days_left
    end

  end

  module ProRata
    include Common

    def allocate(amount, against_due_amounts_val)
      raise TypeError, "A value of currency is needed for money calculations and is not available" unless (respond_to?(:currency) and currency)
      zero_money = Money.zero_money_amount(currency)

      against_due_amounts = against_due_amounts_val.is_a?(Hash) ? against_due_amounts_val : amortization_to_due_amounts(against_due_amounts_val)

      amount_hsh = total_principal_and_interest(against_due_amounts)
      total_principal, total_interest = amount_hsh[:principal], amount_hsh[:interest]
      total = total_principal + total_interest

      interest = zero_money; principal = zero_money; amount_not_allocated = zero_money;
      unless amount < total
        interest, principal = total_interest, total_principal
        amount_not_allocated = amount - total
      else
        interest = amount * (total_interest.amount.to_f/total.amount.to_f); principal = amount - interest
        amount_not_allocated = zero_money
      end
      
      {:principal => principal, :interest => interest, :amount_not_allocated => amount_not_allocated}
    end

  end

  module EarliestInterestThenEarliestPrincipal
    include Common

    def allocate(amount, against_due_amounts_val)
      amount_remaining = amount
      raise TypeError, "A value of currency value is needed for money calculations and is not available" unless (respond_to?(:currency) and currency)
      zero_money = Money.zero_money_amount(currency)

      against_due_amounts = against_due_amounts_val.is_a?(Hash) ? against_due_amounts_val : amortization_to_due_amounts(against_due_amounts_val)

      interest = zero_money; principal = zero_money

      installments = against_due_amounts.keys.sort
      installments.each { |inst|
        break unless amount_remaining.amount > 0
        principal_per_round = zero_money; interest_per_round = zero_money

        interest_due = against_due_amounts[inst][:interest]
        principal_due = against_due_amounts[inst][:principal]

        interest_per_round = [interest_due, amount_remaining].min
        interest += interest_per_round
        amount_remaining -= interest_per_round
        amount_remaining = [amount_remaining, zero_money].max

        break unless amount_remaining.amount > 0
        principal_per_round = [principal_due, amount_remaining].min
        principal += principal_per_round
        amount_remaining -= principal_per_round
      }
      
      {:principal => principal, :interest => interest, :amount_not_allocated => amount_remaining}
    end
  end

  module InterestFirstThenPrincipal
    include Common

    def allocate(amount, against_due_amounts_val)
      raise TypeError, "A value of currency is needed for money calculations and is not available" unless (respond_to?(:currency) and currency)
      zero_money = Money.zero_money_amount(currency)

      against_due_amounts = against_due_amounts_val.is_a?(Hash) ? against_due_amounts_val : amortization_to_due_amounts(against_due_amounts_val)

      amount_hsh = total_principal_and_interest(against_due_amounts)
      total_principal, total_interest = amount_hsh[:principal], amount_hsh[:interest]
      total = total_principal + total_interest

      interest = zero_money; principal = zero_money; amount_not_allocated = zero_money
      unless amount < total
        interest = total_interest; principal = total_principal
        amount_not_allocated = amount - total
      else
        interest = [total_interest, amount].min; principal = amount - interest
        amount_not_allocated = zero_money
      end
      
      {:principal => principal, :interest => interest, :amount_not_allocated => amount_not_allocated}
    end
  end

end