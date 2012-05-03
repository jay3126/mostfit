module Allocation

  # Namespace for modules that implement commonly-used practices of allocation to
  # principal and interest across installments

  module Common

    # Given a series of installments, this returns a data structure that has the
    # total principal amount and total interest amount
    # Data structure is as follows for due amounts
    # amounts = { 1 => {:principal => 100, :interest => 20}, 2 => {:principal => 110, :interest => 10} }
    def total_principal_and_interest(due_amounts)
      installments = due_amounts.keys
      total_principal, total_interest = 0, 0
      installments.each { |inst|
        total_principal += due_amounts[inst][:principal]
        total_interest += due_amounts[inst][:interest]
      }
      {:principal => total_principal, :interest => total_interest}
    end
  end


  module ProRata
    include Common

    #
    def allocate(amount, against_due_amounts)
      amount_hsh = total_principal_and_interest(against_due_amounts)
      total_principal, total_interest = amount_hsh[:principal], amount_hsh[:interest]
      total = total_principal + total_interest

      interest = 0; principal = 0; amount_not_allocated = 0;
      unless amount < total
        interest, principal = total_interest, total_principal
        amount_not_allocated = amount - total
      else
        interest = amount * (total_interest.to_f/total.to_f); principal = amount - interest
        amount_not_allocated = 0
      end
      
      {:principal => principal, :interest => interest, :amount_not_allocated => amount_not_allocated}
    end

  end

  module EarliestInterestThenEarliestPrincipal
    def allocate(amount, against_due_amounts)
      amount_remaining = amount
      interest = 0; principal = 0

      installments = against_due_amounts.keys.sort
      installments.each { |inst|
        break unless amount_remaining > 0
        principal_per_round = 0; interest_per_round = 0

        interest_due = against_due_amounts[inst][:interest]
        principal_due = against_due_amounts[inst][:principal]

        interest_per_round = [interest_due, amount_remaining].min
        interest += interest_per_round
        amount_remaining -= interest_per_round
        amount_remaining = [amount_remaining, 0].max

        break unless amount_remaining > 0
        principal_per_round = [principal_due, amount_remaining].min
        principal += principal_per_round
        amount_remaining -= principal_per_round
      }
      
      {:principal => principal, :interest => interest, :amount_not_allocated => amount_remaining}
    end
  end

  module InterestFirstThenPrincipal
    include Common

    def allocate(amount, against_due_amounts)
      amount_hsh = total_principal_and_interest(against_due_amounts)
      total_principal, total_interest = amount_hsh[:principal], amount_hsh[:interest]
      total = total_principal + total_interest

      interest = 0; principal = 0; amount_not_allocated = 0
      unless amount < total
        interest = total_interest; principal = total_principal
        amount_not_allocated = amount - total
      else
        interest = [total_interest, amount].min; principal = amount - interest
        amount_not_allocated = 0
      end
      
      {:principal => principal, :interest => interest, :amount_not_allocated => amount_not_allocated}
    end
  end

end
