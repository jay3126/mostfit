class BranchReport < Report

  attr_accessor :biz_location_branch_id, :date, :page

  def initialize(params, dates, user)
    @date = dates[:date] || Date.today
    @name = "Branch Report for #{@date}"
    @user = user
    location_facade = get_location_facade(@user)
    all_branch_ids = location_facade.all_nominal_branches.collect {|branch| branch.id}
    @biz_location_branch = (params and params[:biz_location_branch_id] and (not (params[:biz_location_branch_id].empty?))) ? params[:biz_location_branch_id] : all_branch_ids
    @page = params.blank? || params[:page].blank? ? 1 : params[:page]
    @limit = 10
    get_parameters(params, user)
  end

  def name
    "Branch Report for #{@date}"
  end

  def self.name
    "Branch Report"
  end

  def get_reporting_facade(user)
    @reporting_facade ||= FacadeFactory.instance.get_instance(FacadeFactory::REPORTING_FACADE, user)
  end

  def get_location_facade(user)
    @location_facade ||= FacadeFactory.instance.get_instance(FacadeFactory::LOCATION_FACADE, user)
  end

  def default_currency
    @default_currency = MoneyManager.get_default_currency
  end

  def generate

    reporting_facade = get_reporting_facade(@user)
    data = {}

    at_branch_ids_ary = @biz_location_branch.is_a?(Array) ? @biz_location_branch.to_a.paginate(:page => @page, :per_page => @limit) : [@biz_location_branch].to_a.paginate(:page => @page, :per_page => @limit)
    data[:branch_ids] = at_branch_ids_ary
    data[:branches] = {}

    at_branch_ids_ary.each do |branch_id|
      branch = BizLocation.get(branch_id)
      branch_id = branch.id
      branch_name = branch.name
      staff_ids = reporting_facade.staff_members_per_location_on_date(branch_id, @date).aggregate(:staff_id)
      all_staffs = staff_ids.blank? ? [] : StaffMember.all(:id => staff_ids)
      center_ids = LocationLink.get_children_ids_by_sql(branch, @date, false)
      all_staffs.each do |staff|
        if staff.is_ro?
          arrears_overdue = overdue_pos_principal = MoneyManager.default_zero_money
          staff_id = staff.id
          staff_name = staff.name
          centers_members_total = LocationManagement.location_ids_managed_by_staff_by_sql(staff_id, @date)
          manage_centers = center_ids & centers_members_total
          manage_clients = manage_centers.blank? ? [] : ClientAdministration.get_client_ids_administered_by_sql(manage_centers, @date)
          overdue_loan_ids = manage_centers.blank? ? [] : get_reporting_facade(User.first).overdue_loans_for_location_center_wise(@date, manage_centers)
          unless overdue_loan_ids.blank?
            loan_principal_disbursed = Lending.sum(:disbursed_amount, :id => overdue_loan_ids)
            loan_receipts = LoanReceipt.all(:lending_id => overdue_loan_ids, :effective_on.lte => @date)
            loan_principal_receipts = loan_receipts.blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance_least_terms(loan_receipts.map(&:principal_received).sum.to_i)
            loan_interest_receipts = loan_receipts.blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance_least_terms(loan_receipts.map(&:interest_received).sum.to_i)
            loan_total_received = loan_principal_receipts + loan_interest_receipts
            loan_scheduled_till_date = BaseScheduleLineItem.all('loan_base_schedule.lending_id' => overdue_loan_ids, :on_date.lte => @date)
            loan_scheduled_principal_due_till_date = loan_scheduled_till_date.blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance_least_terms(loan_scheduled_till_date.map(&:scheduled_principal_due).sum.to_i)
            loan_scheduled_interest_due_till_date = loan_scheduled_till_date.blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance_least_terms(loan_scheduled_till_date.map(&:scheduled_interest_due).sum.to_i)
            loan_total_scheduled_due_till_date = loan_scheduled_principal_due_till_date + loan_scheduled_interest_due_till_date
            loan_principal_disbursed_amt = loan_principal_disbursed.blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance_least_terms(loan_principal_disbursed.to_i)
            overdue_pos_principal = loan_principal_disbursed_amt > loan_principal_receipts ? loan_principal_disbursed_amt - loan_principal_receipts : MoneyManager.default_zero_money
            arrears_overdue = loan_total_scheduled_due_till_date > loan_total_received ? loan_total_scheduled_due_till_date - loan_total_received : MoneyManager.default_zero_money
          end
          number_of_loan_accounts_in_arrear = overdue_loan_ids.count
          loan_ids = LoanAdministration.get_loan_ids_administered_by_sql(manage_centers.flatten, @date, false,'disbursed_loan_status')
          loan_disbursed = loan_ids.blank? ? [] : Lending.sum(:disbursed_amount, :id => loan_ids)
          loan_disbursed_amt = loan_ids.blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance_least_terms(loan_disbursed.to_i)
          loan_schedule_principal_till_date = loan_ids.blank? ? [] : BaseScheduleLineItem.sum(:scheduled_principal_due, 'loan_base_schedule.lending_id' => loan_ids, :on_date.lte => @date)
          loan_schedule_principal_amt = loan_schedule_principal_till_date.blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance_least_terms(loan_schedule_principal_till_date.to_i)
          outstanding_principal = loan_disbursed_amt > loan_schedule_principal_amt ? loan_disbursed_amt - loan_schedule_principal_amt : MoneyManager.default_zero_money
          data[:branches][staff] = {:branch_id => branch_id, :branch_name => branch_name, :staff_name => staff_name, :staff_id => staff_id, :center_count => manage_centers.size, :members_count => manage_clients.size, :manage_center_outstanding => outstanding_principal, :arrears => arrears_overdue,
            :number_of_loan_accounts_in_arrear => number_of_loan_accounts_in_arrear, :overdue_principal => overdue_pos_principal}
        end
      end
    end
    data
  end
end