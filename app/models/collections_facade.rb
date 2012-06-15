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
    biz_location    = BizLocation.get(at_biz_location)
    loan_facade     = FacadeFactory.instance.get_instance(FacadeFactory::LOAN_FACADE, @user)
    location_facade = FacadeFactory.instance.get_instance(FacadeFactory::LOCATION_FACADE, @user)
    center_manager  = @user # Use this center_manager for staff ID, staff name

    loans = location_facade.get_loans_administered(biz_location.id, on_date).compact
    return [] if loans.blank?

    loans           = loans.select{|loan| loan.status == :disbursed_loan_status}
    mf              = FacadeFactory.instance.get_instance(FacadeFactory::MEETING_FACADE, @user)
    meeting_date    = mf.get_meeting_calendar(biz_location).first
    meeting_hours   = meeting_date.blank? ? '00' : meeting_date.meeting_time_begins_hours
    meeting_minutes = meeting_date.blank? ? '00' : meeting_date.meeting_time_begins_minutes
    clients         = ClientAdministration.get_clients_administered(biz_location.id, on_date)

    return [] if clients.blank?
    
    clients.each do |client|
      client_loans = loans.select{|l| l.loan_borrower.counterparty == client}
      if client_loans.blank?
        client_non_loan << client.id
      else
        client_loans.each do |client_loan|
          loan_schedule_items                = loan_facade.previous_and_current_amortization_items(client_loan.id, on_date)
          client_name                        = client.name
          client_id                          = client.id
          client_group_id                    = client.client_group ? client.client_group.id : ''
          client_group_name                  = client.client_group ? client.client_group.name : "Not attached to any group"
          loan_id                            = client_loan.id
          loan_amount                        = client_loan.total_loan_disbursed
          loan_status                        = client_loan.current_loan_status
          loan_disbursal_date                = client_loan.disbursal_date
          loan_due_status                    = client_loan.current_due_status
          loan_days_past_due                 = client_loan.days_past_due
          loan_schedule_status               = '' #TODO
          #loan_days_past_due                = loan_facade.get_days_past_due_on_date(client_loan.id, on_date) || 0
          loan_principal_due                 = ''
          loan_schedule_items                = loan_schedule_items.first if loan_schedule_items.class == Array && loan_schedule_items.compact.size == 1
          if loan_schedule_items.size > 1
            if loan_due_status == :overdue
              loan_schedule_item = loan_schedule_items.first.first
            else
              loan_schedule_item = loan_schedule_items.last.first
            end
          else
            loan_schedule_item = loan_schedule_items.first
          end
          loan_schedule_date                  = loan_schedule_item.first.last
         
          loan_schedule_installment_no        = loan_schedule_item.first.first
          loan_schedule_principal_due         = loan_schedule_item.last[:scheduled_principal_due]
          loan_actual_principal_due           = client_loan.actual_principal_due(loan_schedule_date)
          loan_actual_principal_outstanding   = client_loan.actual_principal_outstanding
          loan_schedule_principal_outstanding = loan_schedule_item.last[:scheduled_principal_outstanding]

          loan_schedule_interest_due          = loan_schedule_item.last[:scheduled_interest_due]
          loan_actual_interest_due            = client_loan.actual_interest_due(loan_schedule_date)
          loan_actual_interest_outstanding    = client_loan.actual_interest_outstanding
          loan_schedule_interest_outstanding  = loan_schedule_item.last[:scheduled_interest_outstanding]

          loan_advance_amount                 = client_loan.current_advance_available

          loan_principal_receipts             = loan_facade.principal_received_on_date(client_loan.id, on_date)
          loan_interest_receipts              = loan_facade.interest_received_on_date(client_loan.id, on_date)
          loan_advance_receipts               = loan_facade.advance_received_on_date(client_loan.id, on_date)

          loan_total_interest_due             = ''
          loan_total_principal_due            = ''
          
          if (loan_actual_principal_due + loan_actual_interest_due) >= loan_advance_amount
            total_amount_to_be_paid = (loan_actual_principal_due + loan_actual_interest_due) - loan_advance_amount
          else
            total_amount_to_be_paid = 0
          end

          collection_sheet_line << CollectionSheetLineItem.new(at_biz_location, biz_location.name, on_date, client_id, client_name, client_group_id,
            client_group_name, loan_id, loan_amount,
            loan_status, loan_disbursal_date, loan_due_status, loan_schedule_installment_no, loan_schedule_date, loan_days_past_due, loan_principal_due,
            loan_schedule_principal_due, loan_schedule_principal_outstanding, loan_schedule_interest_due, loan_schedule_interest_outstanding,
            loan_advance_amount, loan_principal_receipts, loan_interest_receipts, loan_advance_receipts,
            loan_total_principal_due, loan_total_interest_due, 
            loan_actual_principal_due, loan_actual_interest_due,
            loan_actual_principal_outstanding, loan_actual_interest_outstanding, total_amount_to_be_paid)
        end
      end
    end
    groups = collection_sheet_line.group_by{|x| [x.borrower_group_id, x.borrower_group_name]}.map{|c| c[0]}.sort_by { |obj| obj[1] }
    CollectionSheet.new(biz_location.id, biz_location.name, on_date, meeting_hours, meeting_minutes, center_manager.id, center_manager.name, collection_sheet_line, groups)
  end

  #following function will generate the daily collection sheet for staff_member.
  def get_collection_sheet_for_staff(on_date)
    collection_sheet = []

    #Find all centers by loan history on particular date
    biz_locations = LocationManagement.get_locations_for_staff(@user, on_date)

    biz_locations.each do |biz_location|
      collection_sheet << self.get_collection_sheet(biz_location.id, on_date )
    end

    collection_sheet
  end
end
