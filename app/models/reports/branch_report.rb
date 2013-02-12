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
      all_staffs.each do |staff|
        if staff.is_ro?
          arrears_overdue = overdue_pos_principal = MoneyManager.default_zero_money
          staff_id = staff.id
          staff_name = staff.name
          centers_members_total = reporting_facade.locations_managed_by_staffs_on_date(staff.id, @date)
          loan_ids_overdues = get_reporting_facade(User.first).overdue_loans_for_location_center_wise(@date, centers_members_total[:new_location_ids].flatten)
          overdue_loan_ids  = loan_ids_overdues.blank? ? [] : loan_ids_overdues
          unless overdue_loan_ids.blank?
            loan_principal_disbursed = Lending.sum(:disbursed_amount, :id => loan_ids_overdues)
            loan_receipts = LoanReceipt.all(:lending_id => loan_ids_overdues, :effective_on.lte => @date)
            loan_principal_receipts = loan_receipts.blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance_least_terms(loan_receipts.map(&:principal_received).sum.to_i)
            loan_interest_receipts = loan_receipts.blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance_least_terms(loan_receipts.map(&:interest_received).sum.to_i)
            loan_total_received = loan_principal_receipts + loan_interest_receipts
            loan_scheduled_till_date = BaseScheduleLineItem.all('loan_base_schedule.lending_id' => loan_ids_overdues, :on_date.lte => @date)
            loan_scheduled_principal_due_till_date = loan_scheduled_till_date.blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance_least_terms(loan_scheduled_till_date.map(&:scheduled_principal_due).sum.to_i)
            loan_scheduled_interest_due_till_date = loan_scheduled_till_date.blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance_least_terms(loan_scheduled_till_date.map(&:scheduled_interest_due).sum.to_i)
            loan_total_scheduled_due_till_date = loan_scheduled_principal_due_till_date + loan_scheduled_interest_due_till_date
            loan_principal_disbursed_amt = loan_principal_disbursed.blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance_least_terms(loan_principal_disbursed.to_i)
            overdue_pos_principal = loan_principal_disbursed_amt > loan_principal_receipts ? loan_principal_disbursed_amt - loan_principal_receipts : MoneyManager.default_zero_money
            arrears_overdue = loan_total_scheduled_due_till_date > loan_total_received ? loan_total_scheduled_due_till_date - loan_total_received : MoneyManager.default_zero_money
          end
          number_of_loan_accounts_in_arrear = loan_ids_overdues.count
          outstanding_and_overdue_amounts = reporting_facade.sum_all_outstanding_and_overdues_loans_location_centers_on_date(@date, centers_members_total[:new_location_ids].flatten)
          data[:branches][staff] = {:branch_id => branch_id, :branch_name => branch_name, :staff_name => staff_name, :staff_id => staff_id, :centers_members_total => centers_members_total, :outstanding_and_overdue_amounts => outstanding_and_overdue_amounts, :arrears => arrears_overdue,
            :number_of_loan_accounts_in_arrear => number_of_loan_accounts_in_arrear, :overdue_principal => overdue_pos_principal}
        end
      end
    end
    data
  end
end