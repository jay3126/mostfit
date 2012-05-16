# This facade serves functionality from the collections sub-system
class CollectionsFacade

  attr_reader :user_id, :created_at

  def initialize(user_id)
    @user = StaffMember.get(user_id); @created_at = DateTime.now
  end

  # This returns instances of CollectionSheet which represent
  # the collection sheet at a center location on a given date
  #following function will generte the weeksheet for center.
  def get_collection_sheet(at_center, on_date)
    collection_sheet_line = []

    center = Center.get(at_center)
    center_manager = center.manager # Use this center_manager for staff ID, staff name


    loans = center.loans
    lids = loans.map{|l| l.id}


    # Find all Loan Histories on center
    histories = LoanHistory.all(:loan_id => lids, :date => on_date, :status => [:outstanding, :disbursed])
    fees_paid = {}

    # Find Paid Fee on Loans
    Payment.all(:received_on => on_date, :type => :fees, :loan_id => lids, :fields => [:id, :amount]).map{|p| fees_paid[p.loan_id]||=0; fees_paid[p.loan_id] +=  p.amount}

    # Find all clients of Center
    clients = Client.all(:center_id => at_center, :active => true, :date_joined.lte => on_date, :fields => [:id, :name, :client_group_id, :center_id])

    clients.each do |client|

      loans.find_all{|x| x.client_id==client.id and (x.approved_on || x.disbursal_date)}.each do |loan|

        # Find latest loan history on particular loan
        lh = histories.find_all{|x| x.loan_id==loan.id}.sort_by{|x| x.created_at}[-1]

        next if not lh
        next if lh and LOANS_NOT_PAYABLE.include?(lh.status) and not (lh.principal_paid>0 or lh.interest_paid>0)
        next unless loan.respond_to?(:approved_on) and loan.approved_on <= on_date

        if lh and lh.total_principal_due and lh.total_principal_due > 0
          pdue = lh.total_principal_due - lh.total_principal_paid
          idue = lh.total_interest_due - lh.total_interest_paid
        else
          pdue = [(lh ? lh.principal_due : 0), 0].max
          idue = [(lh ? lh.interest_due : 0), 0].max
        end

        ppaid = (lh ? lh.principal_paid : 0)
        ipaid = [(lh ? lh.interest_paid : 0), 0].max
        fee_due = loan.total_fees_payable_on(on_date)
        fee_paid = fees_paid[loan.id] || 0

        #following are the fields for display on view side.
        client_name = client.name
        client_id = client.id
        client_group_id = client.client_group.id
        client_group_name = (client.client_group ? client.client_group.name : "Not attached to any group")
        loan_id = loan.id
        loan_amount = loan.amount
        loan_outstanding_principal = lh ? lh.actual_outstanding_principal : 0
        loan_disbursal_date = loan.disbursal_date
        loan_installments_paid_till_date = loan.number_of_installments_before(on_date)
        principal_due = pdue
        principal_paid = ppaid
        interest_due = idue
        interest_paid = ipaid
        fees_due = fee_due
        fees_paid = fee_paid
        total_due = (pdue + idue + fee_due)
        total_paid = (ppaid + ipaid + fee_paid)

        loan_status = lh.status

        collection_sheet_line << CollectionSheetLineItem.new(at_center, center.name, on_date, client_id, client_name, client_group_id,
                                                             client_group_name, loan_id, loan_amount,
                                                             loan_outstanding_principal, loan_disbursal_date,
                                                             loan_installments_paid_till_date, principal_due,
                                                             principal_paid, interest_due, interest_paid,
                                                             fees_due, fees_paid, total_due, total_paid, loan_status)
      end
    end
    groups = collection_sheet_line.group_by{|x| [x.borrower_group_id, x.borrower_group_name]}.map{|c| c[0]}.sort_by { |obj| obj[1] }
    CollectionSheet.new(center.id, center.name, on_date, center.meeting_time_hours, center.meeting_time_minutes, center_manager.id, center_manager.name, collection_sheet_line, groups)
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
