class BranchWiseDisbursementAndChargeDetailsReport < Report

  attr_accessor :from_date, :to_date, :biz_location_branch, :lending_product_id

  def initialize(params, dates, user)
    @from_date = (dates and dates[:from_date]) ? dates[:from_date] : Date.today - 7
    @to_date   = (dates and dates[:to_date]) ? dates[:to_date] : Date.today
    @name = "Disbursement and Charge Details Report"
    @user = user
    location_facade = get_location_facade(@user)
    all_branch_ids = location_facade.all_nominal_branches.collect {|branch| branch.id}
    @biz_location_branch = (params and params[:biz_location_branch] and (not (params[:biz_location_branch].empty?))) ? params[:biz_location_branch] : all_branch_ids
    get_parameters(params, user)
  end

  def name
    "Disbursement and Charge Details Report from #{@from_date} to #{@to_date}"
  end

  def self.name
    "Disbursement and Charge Details Report"
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
    location_facade  = get_location_facade(@user)
    data = {}

=begin
columns required in this report are as follows:
1. Disbursal Date
2. Branch Name
3. Disbursements of Each Lending Product (number)
4. Amount of Disbursement of each Lending Product
5. Upfront charges collected.
6. Upfront charges due
7. Total disbursements.
8. Total amount disbursed.
9. Total upfront charges due.
10. Total upfront charges collected.
=end

  end
end
