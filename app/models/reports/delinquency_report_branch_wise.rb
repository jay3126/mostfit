class DelinquencyReportBranchWise < Report
  attr_accessor :biz_location_branch_id, :date, :page

  def initialize(params, dates, user)
    @date = dates[:date] || Date.today
    @name = "Delinquency Report Branch Wise"
    @user = user
    @user = user
    location_facade = FacadeFactory.instance.get_instance(FacadeFactory::LOCATION_FACADE, @user)
    all_branch_ids = location_facade.all_nominal_branches.collect {|branch| branch.id}
    @biz_location_branch = (params and params[:biz_location_branch_id] and (not (params[:biz_location_branch_id].empty?))) ? params[:biz_location_branch_id] : all_branch_ids
    get_parameters(params, user)
  end

  def name
    "Delinquency Report Branch Wise for #{@date}"
  end

  def self.name
    "Delinquency Report - Branch Wise"
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
    reporting_facade = FacadeFactory.instance.get_instance(FacadeFactory::REPORTING_FACADE, @user)
    data = {}
    at_branch_ids_ary = @biz_location_branch.is_a?(Array) ? @biz_location_branch : [@biz_location_branch]
    at_branch_ids_ary.each { |branch_id|
      all_payments                      = reporting_facade.sum_all_loans_balances_at_accounted_locations_on_date_for_delinquency_report(@date, *branch_id)
      amounts                           = all_payments.values.first
      loan_total_repay_principal_amt = amounts['total_principal_amt']
      loan_disbursed_principal_amt   = amounts['disbursed_principal_amt']
      loan_repayment_principal_amt   = amounts['principal_amt']
      loan_repayment_interest_amt    = amounts['interest_amt']
      loan_outstanding_principal     = loan_disbursed_principal_amt - loan_total_repay_principal_amt
      loan_overdue_principal         = amounts['scheduled_principal_amt'] > loan_repayment_principal_amt ? (amounts['scheduled_principal_amt'] - loan_repayment_principal_amt) : MoneyManager.default_zero_money
      loan_overdue_interest          = amounts['scheduled_interest_amt'] > loan_repayment_interest_amt ? (amounts['scheduled_interest_amt'] - loan_repayment_interest_amt) : MoneyManager.default_zero_money
      loan_overdue                   = loan_overdue_principal + loan_overdue_interest
      if loan_outstanding_principal.amount > MoneyManager.default_zero_money.amount
        par_value = (loan_overdue_principal.amount.to_f)/(loan_outstanding_principal.amount.to_f)
        par = ('%.2f' % par_value)
      else
        par = 0.0
      end
      
      branch_data_map                                    = {}
      branch_data_map[:loan_outstanding_principal]       = loan_outstanding_principal
      branch_data_map[:loan_overdue_principal]           = loan_overdue
      branch_data_map[:loan_overdue]                     = loan_overdue_principal
      branch_data_map[:par]                              = par

      data[branch_id]                                    = branch_data_map
    }
    data
  end
end