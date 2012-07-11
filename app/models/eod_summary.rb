class EodSummary

  attr_reader :total_new_loan_application,
    :loans_pending_approval,
    :loans_approved_today,
    :loans_scheduled_for_disbursement,
    :loans_disbursed_today,
    :total_repayment_due,
    :total_repayment_received,
    :total_repayment_outstanding,
    :total_advance_adjusted,
    :total_advance_available,
    :total_fee_collect,
    :total_interest_accrued,
    :no_of_loans_preclosed,
    :total_money_deposits_recorded_today,
    :total_money_deposits_verified_confirmed,
    :total_money_deposits_verified_rejected,
    :total_money_deposits_pending_verification,
    :staff_member_attendance,
    :surprise_center_visits

  def initialize(total_new_loan_application='', loans_pending_approval='', loans_approved_today='', loans_scheduled_for_disbursement='',
      loans_disbursed_today='',
      total_repayment_due='',
      total_repayment_received='',
      total_repayment_outstanding='',
      total_advance_adjusted='',
      total_advance_available='',
      total_fee_collect='',
      total_interest_accrued='',
      no_of_loans_preclosed='',
      total_money_deposits_recorded_today='',
      total_money_deposits_verified_confirmed='',
      total_money_deposits_verified_rejected='',
      total_money_deposits_pending_verification='',
      staff_member_attendance='',
      surprise_center_visits='')

    @total_new_loan_application                = total_new_loan_application
    @loans_pending_approval                    = loans_pending_approval
    @loans_approved_today                      = loans_approved_today
    @loans_scheduled_for_disbursement          = loans_scheduled_for_disbursement
    @loans_disbursed_today                     = loans_disbursed_today
    @total_repayment_due                       = total_repayment_due
    @total_repayment_received                  = total_repayment_received
    @total_repayment_outstanding               = total_repayment_outstanding
    @total_advance_adjusted                    = total_advance_adjusted
    @total_advance_available                   = total_advance_available
    @total_fee_collect                         = total_fee_collect
    @total_interest_accrued                    = total_interest_accrued
    @no_of_loans_preclosed                     = no_of_loans_preclosed
    @total_money_deposits_recorded_today       = total_money_deposits_recorded_today
    @total_money_deposits_verified_confirmed   = total_money_deposits_verified_confirmed
    @total_money_deposits_verified_rejected    = total_money_deposits_verified_rejected
    @total_money_deposits_pending_verification = total_money_deposits_pending_verification
    @staff_member_attendance                   = staff_member_attendance
    @surprise_center_visits                    = surprise_center_visits

  end

  def summary
    {:total_new_loan_application => total_new_loan_application,
    :loans_pending_approval => loans_pending_approval,
    :loans_approved_today => loans_approved_today,
    :loans_scheduled_for_disbursement => loans_scheduled_for_disbursement,
    :loans_disbursed_today => loans_disbursed_today,
    :total_repayment_due => total_repayment_due,
    :total_repayment_received => total_repayment_received,
    :total_repayment_outstanding => total_repayment_outstanding,
    :total_advance_adjusted => total_advance_adjusted,
    :total_advance_available => total_advance_available,
    :total_fee_collect => total_fee_collect,
    :total_interest_accrued => total_interest_accrued,
    :no_of_loans_preclosed => no_of_loans_preclosed,
    :total_money_deposits_recorded_today => total_money_deposits_recorded_today,
    :total_money_deposits_verified_confirmed => total_money_deposits_verified_confirmed,
    :total_money_deposits_verified_rejected => total_money_deposits_verified_rejected,
    :total_money_deposits_pending_verification => total_money_deposits_pending_verification,
    :staff_member_attendance => staff_member_attendance,
    :surprise_center_visits =>  surprise_center_visits}
  end
end
