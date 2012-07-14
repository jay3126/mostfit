class ConsolidatedReport < Report
  attr_accessor :from_date, :to_date, :biz_location_branch

  def initialize(params, dates, user)
    @from_date = (dates and dates[:from_date]) ? dates[:from_date] : Date.today - 7
    @to_date   = (dates and dates[:to_date]) ? dates[:to_date] : Date.today
    @name = "Consolidated Report from #{@from_date} to #{@to_date}"
    @user = user
    location_facade = get_location_facade(@user)
    all_branch_ids = location_facade.all_nominal_branches.collect {|branch| branch.id}
    @biz_location_branch = (params and params[:biz_location_branch] and (not (params[:biz_location_branch].empty?))) ? params[:biz_location_branch] : all_branch_ids
    get_parameters(params, user)
  end

  def name
    "Consolidated Report from #{@from_date} to #{@to_date}"
  end

  def self.name
    "Consolidated Report"
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
      loans_applied = reporting_facade.loans_applied_by_branches_for_date_range(@from_date, @to_date, *branch_id)
      loans_approved = reporting_facade.loans_approved_by_branches_for_date_range(@from_date, @to_date, *branch_id)
      loans_scheduled_for_disbursement = reporting_facade.loans_scheduled_for_disbursement_by_branches_for_date_range(@from_date, @to_date, *branch_id)
      loans_disbursed = reporting_facade.loans_disbursed_by_branches_for_date_range(@from_date, @to_date, *branch_id)

      loan_balances = reporting_facade.sum_all_outstanding_loans_balances_accounted_at_locations_for_date_range(@from_date, @to_date, *branch_id)
      fee_receipts = reporting_facade.all_aggregate_fee_receipts_by_branches(@from_date, @to_date, *branch_id)
      loan_receipts = reporting_facade.all_receipts_on_loans_accounted_at_locations_for_date_range(@from_date, @to_date, *branch_id)
      loan_payments = reporting_facade.all_payments_on_loans_accounted_at_locations_for_date_range(@from_date, @to_date, *branch_id)
      loan_net_payments = reporting_facade.net_payments_on_loans_accounted_at_locations_for_date_range(@from_date, @to_date, *branch_id)
      loan_allocations = reporting_facade.total_loan_allocation_receipts_accounted_at_locations_for_date_range(@from_date, @to_date, *branch_id)

      branch_data_map = {}
      branch_data_map[:loans_applied] = loans_applied
      branch_data_map[:loans_approved] = loans_approved
      branch_data_map[:loans_scheduled_for_disbursement] = loans_scheduled_for_disbursement
      branch_data_map[:loans_disbursed] = loans_disbursed
      branch_data_map[:loan_balances] = loan_balances
      branch_data_map[:fee_receipts] = fee_receipts
      branch_data_map[:loan_receipts] = loan_receipts
      branch_data_map[:loan_payments] = loan_payments
      branch_data_map[:loan_net_payments] = loan_net_payments
      branch_data_map[:loan_allocations] = loan_allocations

      data[branch_id] = branch_data_map
    }    
    data
    
  end

end
