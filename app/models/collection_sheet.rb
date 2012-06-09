# A simple representation of collection sheet
class CollectionSheet

  attr_reader :at_biz_location_id,
    :at_biz_location_name,
    :on_date,
    :at_meeting_time_begins_hours,
    :at_meeting_time_begins_minutes,
    :by_staff_member_id,
    :by_staff_member_name,
    :collection_sheet_lines,
    :groups #An array of group IDs and names

  def initialize(at_biz_location_id, at_biz_location_name, on_date, meeting_time_begins_hours, meeting_time_begins_minutes, by_staff_member_id, by_staff_member_name, collection_sheet_lines,groups)

    @at_biz_location_id             =  at_biz_location_id
    @at_biz_location_name           =  at_biz_location_name
    @on_date                        =  on_date
    @at_meeting_time_begins_hours   =  meeting_time_begins_hours
    @at_meeting_time_begins_minutes =  meeting_time_begins_minutes
    @by_staff_member_id             =  by_staff_member_id
    @by_staff_member_name           =  by_staff_member_name
    @collection_sheet_lines         =  collection_sheet_lines
    @groups                         =  groups

  end

end

# A collection sheet consists of multiple collection sheet line items
# Each such line item represents any payments due
class CollectionSheetLineItem

  attr_reader :at_biz_location_id, :at_biz_location_name, :on_date, :borrower_id, :borrower_name, :borrower_group_id, :borrower_group_name,
               :loan_id, :loan_disbursed_amount, :loan_status, :loan_disbursed_date, :loan_due_status, :loan_installment_number,
               :loan_schedule_date, :loan_days_past_due, :loan_principal_due,:loan_schedule_principal_due, :loan_schedule_principal_outstanding,
               :loan_schedule_interest_due, :loan_schedule_interest_outstanding, :loan_advance_amount, :loan_principal_receipts, :loan_interest_receipts,
               :loan_advance_receipts, :loan_total_principal_due, :loan_total_interest_due, :loan_actual_principal_due, :loan_actual_interest_due,
               :loan_actual_principal_outstanding, :loan_actual_interest_outstanding, :total_amount_paid

  def initialize(at_biz_location_id, at_biz_location_name, on_date, borrower_id, borrower_name, borrower_group_id, borrower_group_name,
                  loan_id, loan_disbursed_amount,loan_status, loan_disbursal_date, loan_due_status, loan_schedule_installment_no,
                  loan_schedule_date, loan_days_past_due, loan_principal_due,loan_schedule_principal_due, loan_schedule_principal_outstanding,
                  loan_schedule_interest_due, loan_schedule_interest_outstanding,loan_advance_amount, loan_principal_receipts, loan_interest_receipts,
                  loan_advance_receipts,loan_total_principal_due, loan_total_interest_due, loan_actual_principal_due, loan_actual_interest_due,
                  loan_actual_principal_outstanding, loan_actual_interest_outstanding, total_amount_paid)

    @at_biz_location_id                  = at_biz_location_id
    @at_biz_location_name                = at_biz_location_name
    @on_date                             = on_date
    @borrower_id                         = borrower_id
    @borrower_name                       = borrower_name
    @borrower_group_id                   = borrower_group_id
    @borrower_group_name                 = borrower_group_name
    @loan_id                             = loan_id
    @loan_disbursed_amount               = loan_disbursed_amount
    @loan_disbursed_date                 = loan_disbursal_date
    @loan_status                         = loan_status
    @loan_installment_number             = loan_schedule_installment_no
    @loan_due_status                     = loan_due_status
    @loan_schedule_date                  = loan_schedule_date
    @loan_days_past_due                  = loan_days_past_due
    @loan_principal_due                  = loan_principal_due
    @loan_schedule_principal_due         = loan_schedule_principal_due
    @loan_schedule_principal_outstanding = loan_schedule_principal_outstanding
    @loan_schedule_interest_due          = loan_schedule_interest_due
    @loan_schedule_interest_outstanding  = loan_schedule_interest_outstanding
    @loan_advance_amount                 = loan_advance_amount
    @loan_principal_receipts             = loan_principal_receipts
    @loan_interest_receipts              = loan_interest_receipts
    @loan_advance_receipts               = loan_advance_receipts
    @loan_total_principal_due            = loan_total_principal_due
    @loan_total_interest_due             = loan_total_interest_due
    @loan_actual_principal_due           = loan_actual_principal_due
    @loan_actual_interest_due            = loan_actual_interest_due
    @loan_actual_principal_outstanding   = loan_actual_principal_outstanding
    @loan_actual_interest_outstanding    = loan_actual_interest_outstanding
    @total_amount_paid                   = total_amount_paid

  end

end
