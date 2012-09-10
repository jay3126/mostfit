class BranchReport < Report

  attr_accessor :biz_location_branch, :date

  def initialize(params, dates, user)
    @date = dates[:date] || Date.today
    @name = "Branch Report for #{@date}"
    @user = user
    location_facade = get_location_facade(@user)
    all_branch_ids = location_facade.all_nominal_branches.collect {|branch| branch.id}
    @biz_location_branch = (params and params[:biz_location_branch] and (not (params[:biz_location_branch].empty?))) ? params[:biz_location_branch] : all_branch_ids
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

  def get_client_facade(user)
    @client_facade ||= FacadeFactory.instance.get_instance(FacadeFactory::CLIENT_FACADE, user)
  end

  def default_currency
    @default_currency = MoneyManager.get_default_currency
  end

  def generate

    reporting_facade = get_reporting_facade(@user)
    location_facade  = get_location_facade(@user)
    client_facade = get_client_facade(@user)
    data = {}

    at_branch_ids_ary = @biz_location_branch.is_a?(Array) ? @biz_location_branch : [@biz_location_branch]
    at_branch_ids_ary.each do |branch_id|
      branch = BizLocation.get(branch_id)
      branch_id = branch.id
      branch_name = branch.name
      outstanding_and_overdue_amounts = reporting_facade.sum_all_outstanding_and_overdues_loans_per_branch_on_date(@date, branch_id)
      arrears = ""
      number_of_loan_accounts_in_arrear = ""
      all_staffs = reporting_facade.staff_members_per_location_on_date(branch_id, @date).aggregate(:staff_id)
      all_staffs.each do |s|
        staff = StaffMember.get(s)
        staff_id = staff.id
        staff_name = staff.name
        centers_members_total = reporting_facade.locations_managed_by_staffs_on_date(staff.id, @date)
        data[staff] = {:branch_id => branch_id, :branch_name => branch_name, :staff_name => staff_name, :staff_id => staff_id, :centers_members_total => centers_members_total, :outstanding_and_overdue_amounts => outstanding_and_overdue_amounts, :arrears => arrears, :number_of_loan_accounts_in_arrear => number_of_loan_accounts_in_arrear}
      end
    end
    data
  end
end
