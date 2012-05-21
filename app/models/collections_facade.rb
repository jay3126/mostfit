# This facade serves functionality from the collections sub-system
class CollectionsFacade

  attr_reader :user_id, :created_at

  def initialize(user_id)
    @user = StaffMember.get(user_id); @created_at = DateTime.now
  end

  # This returns instances of CollectionSheet which represent
  # the collection sheet at a center location on a given date
  #following function will generte the weeksheet for center.
  def get_collection_sheet(at_biz_location, on_date)
    collection_sheet_line = []

    biz_location = BizLocation.get(at_biz_location)
    center_manager = Staff.first # Use this center_manager for staff ID, staff name


    loans = biz_location.landings
    return [] if loans.blank?

    mf = FacadeFactory.instance.get_instance(FacadeFactory::MEETING_FACADE, @user)
    meeting_dates = mf.get_meeting_calendar(biz_location)
    meeting_schedule = biz_location.meeting_schedules.first
    clients = biz_location.clients

    return [] if clients.blank?

    loans.each do |client_loan|
      client = loans.counterparty
      unless client.blank?
        client_name                        = client.name
        client_id                          = client.id
        client_group_id                    = client.client_group.id
        client_group_name                  = (client.client_group ? client.client_group.name : "Not attached to any group")
        loan_id                            = client_loan.id
        loan_amount                        = client_loan.disbursed_amount
        loan_principal_outstanding_on_date = 0
        loan_disbursal_date                = client_loan.disbursal_date
        loan_status                        = client_loan.status

        loan_base_schedule                 = client_loan.loan_base_schedule
        loan_schedule_item                 = loan_base_schedule.get_previous_and_current_amortization_items(on_date)
        loan_installments_paid_till_date   = loan_schedule_item.first.first.first
        schedule_principal_due             = loan_schedule_item.first.last[:scheduled_principal_due]
        schedule_principal_paid            = loan_schedule_item.first.last[:scheduled_principal_outstanding]
        schedule_interest_due              = loan_schedule_item.first.last[:scheduled_interest_due]
        schedule_interest_paid             = loan_schedule_item.first.last[:scheduled_interest_outstanding]
        schedule_fees_due                  = 0
        schedule_fees_paid                 = 0
        total_due                          = (schedule_principal_due + schedule_interest_due + schedule_fees_due)
        total_paid                         = (schedule_principal_paid + schedule_interest_paid+ schedule_fees_paid)

        collection_sheet_line << CollectionSheetLineItem.new(at_biz_location, biz_location.name, on_date, client_id, client_name, client_group_id,
                                                             client_group_name, loan_id, loan_amount,
                                                             loan_principal_outstanding_on_date, loan_disbursal_date,
                                                             loan_installments_paid_till_date, schedule_principal_due,
                                                             schedule_principal_paid, schedule_interest_due, schedule_interest_paid,
                                                             schedule_fees_due, schedule_fees_paid, total_due, total_paid, loan_status)
      end
    end

    groups = collection_sheet_line.group_by{|x| [x.borrower_group_id, x.borrower_group_name]}.map{|c| c[0]}.sort_by { |obj| obj[1] }
    CollectionSheet.new(biz_location.id, biz_location.name, on_date, meeting_schedule.meeting_time_begins_hours, meeting_schedule.meeting_time_begins_minutes, center_manager.id, center_manager.name, collection_sheet_line, groups)
  end

  #following function will generate the daily collection sheet for staff_member.
  def get_collection_sheet_for_staff(on_date)
    collection_sheet = []

    #Find all centers by loan history on particular date
    center_ids = LoanHistory.all(:date => [on_date, on_date.holidays_shifted_today].uniq, :fields => [:loan_id, :date, :center_id], :status => [:disbursed, :outstanding]).map{|x| x.center_id}.uniq
    centers = @user.centers(:id => center_ids, :order=>[:meeting_time_hours, :meeting_time_minutes])

    centers.each do |center|
      collection_sheet << self.get_collection_sheet(center.id, on_date )
    end

    collection_sheet
  end
end
