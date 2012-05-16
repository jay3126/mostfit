# A simple representation of collection sheet
class CollectionSheet
  
  attr_reader :at_center_id, 
    :at_center_name,
    :on_date,
    :at_meeting_time_begins_hours,
    :at_meeting_time_begins_minutes,
    :by_staff_member_id,
    :by_staff_member_name,
    :collection_sheet_lines,
    :groups #An array of group IDs and names

  def initialize(at_center_id, at_center_name, on_date, meeting_time_begins_hours, meeting_time_begins_minutes, by_staff_member_id, by_staff_member_name, collection_sheet_lines,groups)

    @at_center_id                   =  at_center_id
    @at_center_name                 =  at_center_name
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

  attr_reader :at_center_id, :at_center_name, :on_date, :borrower_id, :borrower_name, :borrower_group_id, :borrower_group_name, :loan_id, :loan_disbursed_amount, :loan_disbursed_date, :loan_installment_number, :loan_outstanding, :fee_due_today, :fee_paid_today, :interest_due_today, :interest_paid_today, :principal_due_today, :principal_paid_today, :total_due, :total_paid, :loan_status

  def initialize(at_center_id, at_center_name, on_date, borrower_id, borrower_name, borrower_group_id, borrower_group_name, loan_id, loan_disbursed_amount, loan_outstanding_principal, loan_disbursal_date, loan_installments_paid_till_date, principal_due, principal_paid, interest_due, interest_paid, fees_due, fees_paid, total_due, total_paid, loan_status)

    @at_center_id            =  at_center_id
    @at_center_name          =  at_center_name
    @on_date                 =  on_date
    @borrower_id             =  borrower_id
    @borrower_name           =  borrower_name
    @borrower_group_id       =  borrower_group_id
    @borrower_group_name     =  borrower_group_name
    @loan_id                 =  loan_id
    @loan_disbursed_amount   =  loan_disbursed_amount
    @loan_disbursed_date     =  loan_disbursal_date
    @loan_installment_number =  loan_installments_paid_till_date
    @loan_outstanding        =  loan_outstanding_principal
    @fee_due_today           =  fees_due
    @interest_due_today      =  interest_due
    @principal_due_today     =  principal_due
    @fee_paid_today          =  fees_paid
    @interest_paid_today     =  interest_paid
    @principal_paid_today    =  principal_paid
    @total_due               =  total_due
    @total_paid              =  total_paid
    @loan_status             =  loan_status

  end

end
