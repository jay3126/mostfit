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
    client_non_loan       = []
    biz_location = BizLocation.get(at_biz_location)
    loan_facade = FacadeFactory.instance.get_instance(FacadeFactory::LOAN_FACADE, @user)
    location_facade = FacadeFactory.instance.get_instance(FacadeFactory::LOCATION_FACADE, @user)
    center_manager = Staff.first # Use this center_manager for staff ID, staff name

    loans = location_facade.get_loans_administered(biz_location.id, on_date).compact
    return [] if loans.blank?

    mf = FacadeFactory.instance.get_instance(FacadeFactory::MEETING_FACADE, @user)
    #meeting_dates = mf.get_meeting_calendar(biz_location).first
    meeting_dates = MeetingCalendar.first
    clients = ClientAdministration.get_clients_administered(biz_location.id, on_date)

    return [] if clients.blank?

    clients.each do |client|
      client_loan = loans.select{|l| l.for_borrower_id == client.id}.first
      if client_loan.blank?
        client_non_loan << client.id
      else
        loan_schedule_items                = loan_facade.previous_and_current_amortization_items(client_loan.id, on_date)
        client_name                        = client.name
        client_id                          = client.id
        client_group_id                    = client.client_group ? client.client_group.id : ''
        client_group_name                  = client.client_group ? client.client_group.name : "Not attached to any group"
        loan_id                            = client_loan.id
        loan_amount                        = client_loan.to_money[:disbursed_amount]
        loan_status                        = loan_facade.get_current_loan_status(client_loan.id)
        loan_disbursal_date                = client_loan.disbursal_date
        loan_due_status                    = loan_facade.get_historical_loan_status_on_date(client_loan.id, on_date) || :not_due
        loan_schedule_status               = ''
        loan_days_past_due                 = loan_facade.get_days_past_due_on_date(client_loan.id, on_date) || 0
        loan_principal_due                 = ''
        if loan_schedule_items.size > 1
          if loan_due_status == :overdue
            loan_schedule_item = loan_schedule_items.first.first
          else
            loan_schedule_item = loan_schedule_items.last.first
          end
        else
          loan_schedule_item = loan_schedule_items.first
        end
        loan_schedule_installment_no        = loan_schedule_item.first.first
        loan_schedule_date                  = loan_schedule_item.first.last
        loan_schedule_principal_due         = loan_schedule_item.last[:scheduled_principal_due]
        loan_schedule_principal_outstanding = loan_schedule_item.last[:scheduled_principal_outstanding]
        loan_schedule_interest_due          = loan_schedule_item.last[:scheduled_interest_due]
        loan_schedule_interest_outstanding  = loan_schedule_item.last[:scheduled_interest_outstanding]
        loan_advance_amount                 = ''
        loan_principal_receipts             = loan_facade.principal_received_on_date(client_loan.id, on_date)
        loan_interest_receipts              = loan_facade.interest_received_on_date(client_loan.id, on_date)
        loan_advance_receipts               = loan_facade.advance_received_on_date(client_loan.id, on_date)
        loan_total_interest_due             = ''
        loan_total_principal_due            = ''
        total_paid                          = (loan_total_interest_due + loan_total_principal_due)

        collection_sheet_line << CollectionSheetLineItem.new(at_biz_location, biz_location.name, on_date, client_id, client_name, client_group_id,
          client_group_name, loan_id, loan_amount,
          loan_status, loan_disbursal_date, loan_due_status, loan_schedule_installment_no, loan_schedule_date, loan_days_past_due, loan_principal_due,
          loan_schedule_principal_due, loan_schedule_principal_outstanding, loan_schedule_interest_due, loan_schedule_interest_outstanding,
          loan_advance_amount, loan_principal_receipts, loan_interest_receipts, loan_advance_receipts,
          loan_total_principal_due, loan_total_interest_due, total_paid)
      end
    end

    groups = collection_sheet_line.group_by{|x| [x.borrower_group_id, x.borrower_group_name]}.map{|c| c[0]}.sort_by { |obj| obj[1] }
    CollectionSheet.new(biz_location.id, biz_location.name, on_date, meeting_dates.meeting_time_begins_hours, meeting_dates.meeting_time_begins_minutes, center_manager.id, center_manager.name, collection_sheet_line, groups)
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