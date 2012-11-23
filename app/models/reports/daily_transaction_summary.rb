class DailyTransactionSummary < Report
  attr_accessor :date, :biz_location_branch_id

  def initialize(params, dates, user)
    @date = (dates and dates[:date]) ? dates[:date] : Date.today
    @name   = "Report for #{@date}"
    @user = user
    location_facade = get_location_facade(@user)
    all_branch_ids = location_facade.all_nominal_branches.collect {|branch| branch.id}
    @biz_location_branch = (params and params[:biz_location_branch_id] and (not (params[:biz_location_branch_id].empty?))) ? params[:biz_location_branch_id] : all_branch_ids
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
    data = {}
    
    at_branch_ids_ary = @biz_location_branch.is_a?(Array) ? @biz_location_branch : [@biz_location_branch]
    at_branch_ids_ary.each { |branch_id|

      loans_disbursed              = reporting_facade.loans_disbursed_by_branches_on_date(@date, *branch_id)
      all_payments                 = reporting_facade.sum_all_loans_balances_at_accounted_locations_on_date(@date, *branch_id)
      amounts                      = all_payments.values.first
      loan_repayment_principal_amt = amounts['principal_amt']
      loan_repayment_interest_amt  = amounts['interest_amt']
      loan_fee_amt                 = amounts['fee_amt']
      loan_advance_collect         = amounts['advance_amt']
      loan_advance_adjust          = amounts['advance_adjustment_amt']
      loan_advance_balance         = amounts['total_advance_balance_amt']
      loan_write_off_amt           = amounts['recovery_amt']
      loan_preclose_principal      = amounts['preclose_principal_amt']
      loan_preclose_interest       = amounts['preclose_interest_amt']

      branch_data_map                             = {}
      branch_data_map[:loans_disbursed]           = loans_disbursed
      branch_data_map[:loans_repayment_principal] = loan_repayment_principal_amt
      branch_data_map[:loans_repayment_interest]  = loan_repayment_interest_amt
      branch_data_map[:fee_receipts]              = loan_fee_amt
      branch_data_map[:loans_preclose_principal]  = loan_preclose_principal
      branch_data_map[:loans_preclose_interest]   = loan_preclose_interest
      branch_data_map[:loan_advance_collect]      = loan_advance_collect
      branch_data_map[:loan_advance_adjust]       = loan_advance_adjust
      branch_data_map[:loan_advance_balance]      = loan_advance_balance
      branch_data_map[:loans_recovery]            = loan_write_off_amt
      data[branch_id]                             = branch_data_map
    }
    data
  end
end
