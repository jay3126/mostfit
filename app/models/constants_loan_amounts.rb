module Constants
  module LoanAmounts

    # Demarcate the timeline as follows:
    # Before disbursement: NOT_DUE
    # After disbursement: DUE or OVERDUE
    # After the end of the conventional schedule: Unless the loan is repaid in full, it is OVERDUE

=begin
    TOTAL_LOAN_DISBURSED                                       = "The total loan amount disbursed"
    TOTAL_INTEREST_APPLICABLE                                  = "The total interest amount that was calculated to be applicable at the time the loan was made"
    TOTAL_ADVANCE_ACCUMULATED                                  = "The total advance accumulated against the loan"
    TOTAL_ADVANCE_ADJUSTED                                     = "The total advance adjusted towards loan balances from advance accumulated"
    SCHEDULED_PRINCIPAL_OUTSTANDING                            = "The total principal outstanding as per the schedule"
    SCHEDULED_INTEREST_OUTSTANDING                             = "The total interest amount that is to be received as per the schedule"
    SCHEDULED_PRINCIPAL_DUE                                    = "The principal repayment due on any particular day"
    SCHEDULED_INTEREST_DUE                                     = "The interest receipt due on any particular day"
    PRINCIPAL_OVERDUE                                          = "The principal repayment overdue on any particular date"
    INTEREST_OVERDUE                                           = "The interest receipt overdue on any particular date"
    PRINCIPAL_TO_ALLOCATE                                      = "The amount calculated to be allocated to principal from a larger amount"
    INTEREST_TO_ALLOCATE                                       = "The amount calculated to be allocated to interest from a larger amount"
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

    TOTAL_LOAN_DISBURSED                                       = :total_loan_disbursed
    TOTAL_INTEREST_APPLICABLE                                  = :total_interest_applicable
    TOTAL_ADVANCE_ACCUMULATED                                  = :total_advance_accumulated
    TOTAL_ADVANCE_ADJUSTED                                     = :total_advance_adjusted
    SCHEDULED_PRINCIPAL_OUTSTANDING                            = :scheduled_principal_outstanding
    SCHEDULED_INTEREST_OUTSTANDING                             = :scheduled_interest_outstanding
    SCHEDULED_PRINCIPAL_DUE                                    = :scheduled_principal_due
    SCHEDULED_INTEREST_DUE                                     = :scheduled_interest_due
    PRINCIPAL_OVERDUE                                          = :principal_overdue
    INTEREST_OVERDUE                                           = :interest_overdue
    PRINCIPAL_TO_ALLOCATE                                      = :principal_to_allocate
    INTEREST_TO_ALLOCATE                                       = :interest_to_allocate
    PRINCIPAL_RECEIVED                                         = :principal_received
    INTEREST_RECEIVED                                          = :interest_received
    ADVANCE_RECEIVED                                           = :advance_received
    ADVANCE_ADJUSTED                                           = :advance_adjusted

    PRO_RATA_ALLOCATION                                        = :pro_rata_allocation
    INTEREST_FIRST_THEN_PRINCIPAL_ALLOCATION                   = :interest_first_then_principal_allocation
    EARLIEST_INTEREST_FIRST_THEN_EARLIEST_PRINCIPAL_ALLOCATION = :earliest_interest_first_then_earliest_principal_allocation
    LOAN_REPAYMENT_ALLOCATION_STRATEGIES                       = [
        PRO_RATA_ALLOCATION, INTEREST_FIRST_THEN_PRINCIPAL_ALLOCATION, EARLIEST_INTEREST_FIRST_THEN_EARLIEST_PRINCIPAL_ALLOCATION
    ]

    ALLOCATION_IMPLEMENTATIONS = {
        PRO_RATA_ALLOCATION                                        => Allocation::ProRata,
        INTEREST_FIRST_THEN_PRINCIPAL_ALLOCATION                   => Allocation::InterestFirstThenPrincipal,
        EARLIEST_INTEREST_FIRST_THEN_EARLIEST_PRINCIPAL_ALLOCATION => Allocation::EarliestInterestThenEarliestPrincipal
    }

  end
end