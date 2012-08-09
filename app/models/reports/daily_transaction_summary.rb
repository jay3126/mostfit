class DailyTransactionSummary < Report
  attr_accessor :date, :biz_location_branch

  def initialize(params, dates, user)
    @date = (dates and dates[:date]) ? dates[:date] : Date.today
    @name   = "Report for #{@date}"
    @user = user
    location_facade = get_location_facade(@user)
    all_branch_ids = location_facade.all_nominal_branches.collect {|branch| branch.id}
    @biz_location_branch = (params and params[:biz_location_branch] and (not (params[:biz_location_branch].empty?))) ? params[:biz_location_branch] : all_branch_ids
    get_parameters(params, user)
  end
  
  def name
    "Daily transaction summary for #{@date}"
  end
  
  def self.name
    "Daily transaction summary"
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

      loans_disbursed = reporting_facade.loans_disbursed_by_branches_on_date(@date, *branch_id)
      loan_allocations = reporting_facade.total_loan_allocation_receipts_accounted_at_locations_on_value_date(@date, *branch_id)
      fee_receipts = reporting_facade.all_aggregate_fee_receipts_by_branches(@date, @date, *branch_id)
      loan_balances = reporting_facade.sum_all_outstanding_loans_balances_accounted_at_locations_on_date(@date, *branch_id)
      loan_written_off_values = reporting_facade.aggregate_loans_by_branches_for_written_off_status_on_date(:written_off_loan_status, @date, *branch_id)
      loan_preclosures = reporting_facade.aggregate_loans_by_branches_for_pre_closure_status_on_date(:repaid_loan_status, @date, *branch_id)

      branch_data_map = {}
      branch_data_map[:loans_disbursed] = loans_disbursed
      branch_data_map[:loan_balances] = loan_balances
      branch_data_map[:loan_allocations] = loan_allocations
      branch_data_map[:fee_receipts] = fee_receipts
      branch_data_map[:loan_written_off_values] = loan_written_off_values
      branch_data_map[:loan_preclosures] = loan_preclosures

      data[branch_id] = branch_data_map
    }
    data
  end
end
