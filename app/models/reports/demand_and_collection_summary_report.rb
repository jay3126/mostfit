class DemandAndCollectionSummaryReport < Report

  attr_accessor :date, :biz_location_branch_id, :page

  def initialize(params, dates, user)
    @date = dates[:date] || Date.today
    @name = "Demand And Collection Summary Report for #{@date}"
    @user = user
    location_facade = get_location_facade(@user)
    all_branch_ids = location_facade.all_nominal_branches.collect {|branch| branch.id}
    @biz_location_branch = (params and params[:biz_location_branch_id] and (not (params[:biz_location_branch_id].empty?))) ? params[:biz_location_branch_id] : all_branch_ids
    @page = params.blank? || params[:page].blank? ? 1 :params[:page]
    @limit = 10
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
    data = {}
    at_branch_ids_ary = @biz_location_branch.is_a?(Array) ? @biz_location_branch.paginate(:page => @page, :per_page => @limit) : [@biz_location_branch]
    data[:branch_ids] = at_branch_ids_ary
    data[:branches] = {}

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

      data[:branches][branch_id] = branch_data_map
    }
    data
  end
end