class DemandAndCollectionSummaryReport < Report

  attr_accessor :date, :biz_location_branch

  def initialize(params, dates, user)
    @date = dates[:date] || Date.today
    @name = "Demand And Collection Summary Report for #{@date}"
    @user = user
    location_facade = get_location_facade(@user)
    all_branch_ids = location_facade.all_nominal_branches.collect {|branch| branch.id}
    @biz_location_branch = (params and params[:biz_location_branch] and (not (params[:biz_location_branch].empty?))) ? params[:biz_location_branch] : all_branch_ids
    get_parameters(params, user)
  end

  def name
    "Demand And Collection Summary Report for #{@date}"
  end

  def self.name
    "Demand And Collection Summary Report"
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

    at_branch_ids_ary = @biz_location_branch.is_a?(Array) ? @biz_location_branch : [@biz_location_branch]
    at_branch_ids_ary.each { |branch_id|
      loan_fee_receipts = reporting_facade.aggregate_fee_receipts_on_loans_by_branches(@date, @date, *branch_id)
      all_fee_receipts = reporting_facade.all_aggregate_fee_receipts_by_branches(@date, @date, *branch_id)
      fee_dues = reporting_facade.all_aggregate_fee_dues_by_branches(@date, @date, *branch_id)
      loan_balances = reporting_facade.sum_all_outstanding_loans_balances_accounted_at_locations_on_date(@date, *branch_id)
      loan_allocations = reporting_facade.total_loan_allocation_receipts_accounted_at_locations_on_value_date(@date, *branch_id)

      branch_data_map = {}
      branch_data_map[:loan_fee_receipts] = loan_fee_receipts
      branch_data_map[:all_fee_receipts] = all_fee_receipts
      branch_data_map[:fee_dues] = fee_dues
      branch_data_map[:loan_balances] = loan_balances
      branch_data_map[:loan_allocations] = loan_allocations

      data[branch_id] = branch_data_map
    }
    data

=begin
Columns required in this report are as follows:
1. Branch Name
2. EWI Scheduled
3. EWI Avance
4. EWI Due 
5. EWI Collected.
6. Overdue for the day
7. Overdue amount 
8. Overdue EWI Collected.
9. Fees Collectable
10. Fees Collected.
11. Other Fees Collected 
12. Advance Collected
13. Foreclosure POS
14. Foreclosure Overdue Interest
15. Total Collections
16. Short Collections
17. Differences
=end
  end
end
