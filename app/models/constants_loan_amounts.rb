module Constants
  module LoanAmounts

    # Demarcate the timeline as follows:
    # Before disbursement: NOT_DUE
    # After disbursement: DUE or OVERDUE
    # After the end of the conventional schedule: Unless the loan is repaid in full, it is OVERDUE

=begin
    LOAN_DISBURSED                                             = "A loan disbursement amount"
    TOTAL_LOAN_DISBURSED                                       = "The total loan amount disbursed"
    TOTAL_INTEREST_APPLICABLE                                  = "The total interest amount that was calculated to be applicable at the time the loan was made"
    TOTAL_ADVANCE_ACCUMULATED                                  = "The total advance accumulated against the loan"
    ADVANCE_AVAILABLE                                          = "The net balance available as advance against the loan that has not been adjusted yet"
    TOTAL_ADVANCE_ADJUSTED                                     = "The total advance adjusted towards loan balances from advance accumulated"
    SCHEDULED_PRINCIPAL_OUTSTANDING                            = "The total principal outstanding as per the schedule"
    SCHEDULED_INTEREST_OUTSTANDING                             = "The total interest amount that is to be received as per the schedule"
    ACTUAL_PRINCIPAL_OUTSTANDING                               = "The actual total principal outstanding as per disbursements and receipts"
    ACTUAL_INTEREST_OUTSTANDING                                = "The actual total interest outstanding as per the interest receipts when compared against the TOTAL_INTEREST_APPLICABLE"

    SCHEDULED_PRINCIPAL_DUE                                    = "The principal repayment due on any particular day"
    SCHEDULED_INTEREST_DUE                                     = "The interest receipt due on any particular day"
    PRINCIPAL_OVERDUE                                          = "The principal repayment overdue on any particular date"
    INTEREST_OVERDUE                                           = "The interest receipt overdue on any particular date"

    ACTUAL_PRINCIPAL_DUE                                       = "The actual principal due which may or may not be different from the scheduled principal due on account of either advances accumulated or principal overdue"

    ACTUAL_PRINCIPAL_DUE = max(SCHEDULED_PRINCIPAL_DUE + PRINCIPAL_OVERDUE - ADVANCE_AVAILABLE, 0) ### BE CAREFUL WITH MONEY AMOUNTS IN THESE CALCULATIONS

    PRINCIPAL_TO_ALLOCATE                                      = "The amount calculated to be allocated to principal from a larger amount"
    INTEREST_TO_ALLOCATE                                       = "The amount calculated to be allocated to interest from a larger amount"
    ADVANCE_TO_ALLOCATE                                        = "The amount calculated to be allocated to advance from a larger amount"
    PRINCIPAL_RECEIVED                                         = "The principal repaid on any particular transaction"
    INTEREST_RECEIVED                                          = "The interest received on any particular transaction"
    ADVANCE_RECEIVED                                           = "The advance amount received on any particular transaction"
    ADVANCE_ADJUSTED                                           = "The total advance amount adjusted subsequently to the loan balances from the advance accumulated against the loan"


    PRINCIPAL_OUTSTANDING_ON_DATE                              = "The principal amount that is as yet unpaid on loans that are NOT OVERDUE" aka POS
    PRINCIPAL_AT_RISK_ON_DATE                                  = "The principal amount that is as yet unpaid on OVERDUE loans" aka PAR; therefore PAR + POS = (total principal outstanding)

    # TOTALS
    # TOTAL_LOAN_DISBURSED, TOTAL_INTEREST_APPLICABLE, and TOTAL_ADVANCE_ACCUMULATED are already total amounts
    # When any of the other amounts are being added up in a 'local context', _TOTAL will be suffixed

    # When quantities are to be specified with respect to the point-in-time, the following will be used
    INTEREST_RECEIVED (on a particular transaction)
    INTEREST_RECEIVED_ON_DATE (as on a particular date)
    INTEREST_RECEIVED_TILL_DATE (upto and including a particular date)
=end

    TOTAL_PAID                                                 = :total_paid
    LOAN_DISBURSED                                             = :loan_disbursed
    TOTAL_LOAN_DISBURSED                                       = :total_loan_disbursed
    TOTAL_INTEREST_APPLICABLE                                  = :total_interest_applicable
    TOTAL_ADVANCE_ACCUMULATED                                  = :total_advance_accumulated
    TOTAL_ADVANCE_ADJUSTED                                     = :total_advance_adjusted
    SCHEDULED_PRINCIPAL_OUTSTANDING                            = :scheduled_principal_outstanding
    SCHEDULED_INTEREST_OUTSTANDING                             = :scheduled_interest_outstanding
    SCHEDULED_TOTAL_OUTSTANDING                                = :scheduled_total_outstanding
    SCHEDULED_PRINCIPAL_DUE                                    = :scheduled_principal_due
    SCHEDULED_INTEREST_DUE                                     = :scheduled_interest_due
    SCHEDULED_TOTAL_DUE                                        = :scheduled_total_due
    PRINCIPAL_OVERDUE                                          = :principal_overdue
    INTEREST_OVERDUE                                           = :interest_overdue
    PRINCIPAL_TO_ALLOCATE                                      = :principal_to_allocate
    INTEREST_TO_ALLOCATE                                       = :interest_to_allocate
    ADVANCE_TO_ALLOCATE                                        = :advance_to_allocate
    PRINCIPAL_RECEIVED                                         = :principal_received
    INTEREST_RECEIVED                                          = :interest_received
    LOAN_RECOVERY                                              = :loan_recovery
    ADVANCE_RECEIVED                                           = :advance_received
    TOTAL_RECEIVED                                             = :total_received
    ADVANCE_ADJUSTED                                           = :advance_adjusted
    ACTUAL_PRINCIPAL_OUTSTANDING                               = :actual_principal_outstanding
    PRINCIPAL_AT_RISK                                          = :principal_at_risk
    ACTUAL_INTEREST_OUTSTANDING                                = :actual_interest_outstanding
    ACTUAL_TOTAL_OUTSTANDING                                   = :actual_total_outstanding
    ACTUAL_PRINCIPAL_DUE                                       = :actual_principal_due
    ACTUAL_INTEREST_DUE                                        = :actual_interest_due
    ACTUAL_TOTAL_DUE                                           = :actual_total_due

    LOAN_PRODUCT_AMOUNTS = [LOAN_DISBURSED, PRINCIPAL_RECEIVED, INTEREST_RECEIVED, ADVANCE_RECEIVED, ADVANCE_ADJUSTED, TOTAL_RECEIVED, TOTAL_PAID, LOAN_RECOVERY]

    #PRINCIPAL_OUTSTANDING is ACTUAL_PRINCIPAL_OUTSTANDING when loan is NOT overdue
    #PRINCIPAL_AT_RISK is ACTUAL_PRINCIPAL_OUTSTANDING when loan is OVERDUE

    PRO_RATA_ALLOCATION                                        = :pro_rata_allocation
    INTEREST_FIRST_THEN_PRINCIPAL_ALLOCATION                   = :interest_first_then_principal_allocation
    EARLIEST_INTEREST_FIRST_THEN_EARLIEST_PRINCIPAL_ALLOCATION = :earliest_interest_first_then_earliest_principal_allocation
    LOAN_REPAYMENT_ALLOCATION_STRATEGIES                       = [
        PRO_RATA_ALLOCATION, INTEREST_FIRST_THEN_PRINCIPAL_ALLOCATION, EARLIEST_INTEREST_FIRST_THEN_EARLIEST_PRINCIPAL_ALLOCATION
    ]

    ALLOCATION_IMPLEMENTATIONS = {
        PRO_RATA_ALLOCATION                                        => 'ProRataImpl',
        INTEREST_FIRST_THEN_PRINCIPAL_ALLOCATION                   => 'InterestFirstThenPrincipalImpl',
        EARLIEST_INTEREST_FIRST_THEN_EARLIEST_PRINCIPAL_ALLOCATION => 'EarliestInterestThenEarliestPrincipalImpl'
    }

    def self.get_allocator(of_type, for_currency)
      klass_name = ALLOCATION_IMPLEMENTATIONS[of_type]
      raise ArgumentError, "Unable to locate an implementation for the requested form of allocation: #{of_type}" unless klass_name
      klass = Kernel.const_get(klass_name)
      klass.new(for_currency)
    end

  end
end

class ProRataImpl
  include Allocation::ProRata

  attr_reader :currency
  def initialize(currency)
    @currency = currency
  end
end

class EarliestInterestThenEarliestPrincipalImpl
  include Allocation::EarliestInterestThenEarliestPrincipal

  attr_reader :currency
  def initialize(currency)
    @currency = currency
  end
end

class InterestFirstThenPrincipalImpl
  include Allocation::InterestFirstThenPrincipal

  attr_reader :currency
  def initialize(currency)
    @currency = currency
  end
end
