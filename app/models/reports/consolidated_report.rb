class ConsolidatedReport < Report
  attr_accessor :from_date, :to_date, :biz_location_branch_id

  def initialize(params, dates, user)
    @from_date = (dates and dates[:from_date]) ? dates[:from_date] : Date.today - 7
    @to_date   = (dates and dates[:to_date]) ? dates[:to_date] : Date.today
    @name = "Consolidated Report from #{@from_date} to #{@to_date}"
    @user = user
    location_facade = get_location_facade(@user)
    all_branch_ids = location_facade.all_nominal_branches.collect {|branch| branch.id}
    @biz_location_branch = (params and params[:biz_location_branch_id] and (not (params[:biz_location_branch_id].empty?))) ? params[:biz_location_branch_id] : all_branch_ids
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
      loans_applied                     = reporting_facade.loans_applied_by_branches_for_date_range(@from_date, @to_date, *branch_id)
      loans_approved                    = reporting_facade.loans_approved_by_branches_for_date_range(@from_date, @to_date, *branch_id)
      loans_scheduled_for_disbursement  = reporting_facade.loans_scheduled_for_disbursement_by_branches_for_date_range(@from_date, @to_date, *branch_id)
      loans_disbursed                   = reporting_facade.loans_disbursed_by_branches_for_date_range(@from_date, @to_date, *branch_id)

      all_payments                      = reporting_facade.sum_all_loans_balances_at_accounted_locations_for_date_range(@from_date, @to_date, *branch_id)
      amounts                           = all_payments.values.first
      loan_disbursed_principal_amt      = amounts['disbursed_principal_amt']
      loan_disbursed_interest_amt       = amounts['disbursed_interest_amt']
      loan_repayment_principal_amt      = amounts['principal_amt']
      loan_repayment_interest_amt       = amounts['interest_amt']
      loan_fee_amt                      = amounts['fee_amt']
      loan_outstanding_principal        = loan_disbursed_principal_amt - loan_repayment_principal_amt
      loan_outstanding_interest         = loan_disbursed_interest_amt - loan_repayment_interest_amt
      loan_advance_collect              = amounts['advance_amt']
      loan_advance_adjust               = amounts['advance_adjustment_amt']
      loan_advance_balance              = amounts['total_advance_balance_amt']
      loan_overdue_principal            = amounts['scheduled_principal_amt'] > loan_repayment_principal_amt ? (amounts['scheduled_principal_amt'] - loan_repayment_principal_amt) : MoneyManager.default_zero_money
      loan_overdue_interest             = amounts['scheduled_interest_amt'] > loan_repayment_interest_amt ? (amounts['scheduled_interest_amt'] - loan_repayment_interest_amt) : MoneyManager.default_zero_money

      branch_data_map                                    = {}
      branch_data_map[:loans_applied]                    = loans_applied
      branch_data_map[:loans_approved]                   = loans_approved
      branch_data_map[:loans_scheduled_for_disbursement] = loans_scheduled_for_disbursement
      branch_data_map[:loans_disbursed]                  = loans_disbursed
      branch_data_map[:loans_repayment_principal]        = loan_repayment_principal_amt
      branch_data_map[:loans_repayment_interest]         = loan_repayment_interest_amt
      branch_data_map[:fee_receipts]                     = loan_fee_amt
      branch_data_map[:loan_outstanding_principal]       = loan_outstanding_principal
      branch_data_map[:loan_outstanding_interest]        = loan_outstanding_interest
      branch_data_map[:loan_advance_collect]             = loan_advance_collect
      branch_data_map[:loan_advance_adjust]              = loan_advance_adjust
      branch_data_map[:loan_advance_balance]             = loan_advance_balance
      branch_data_map[:loan_overdue_principal]           = loan_overdue_principal
      branch_data_map[:loan_overdue_interest]            = loan_overdue_interest
      
      data[branch_id]                                    = branch_data_map
    }    
    data
    
  end

end
