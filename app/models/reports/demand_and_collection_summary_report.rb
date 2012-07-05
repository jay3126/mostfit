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
