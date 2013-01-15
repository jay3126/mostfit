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
    at_branch_ids_ary = @biz_location_branch.is_a?(Array) ? @biz_location_branch : [@biz_location_branch]
    data[:branch_ids] = at_branch_ids_ary
    data[:branches] = {}

    at_branch_ids_ary.each { |branch_id|
      branch = BizLocation.get branch_id
      loan_amounts_on_date = reporting_facade.total_dues_collected_and_collectable_per_location_on_date(branch_id, @date)


      branch_data_map = {}
      branch_data_map[:branch_name] = branch.name
      branch_data_map[:ewi_schedule] = loan_amounts_on_date[:scheduled_total]
      branch_data_map[:ewi_advance] = loan_amounts_on_date[:advance_amount_exist]
      branch_data_map[:overdue_ftd] = loan_amounts_on_date[:overdue_ftd]
      branch_data_map[:overdue_amt] = loan_amounts_on_date[:overdue_amt]
      total_demand = loan_amounts_on_date[:scheduled_total] +loan_amounts_on_date[:overdue_ftd]+loan_amounts_on_date[:overdue_amt]
      branch_data_map[:ewi_due] =  total_demand > loan_amounts_on_date[:advance_amount_exist] ? total_demand - loan_amounts_on_date[:advance_amount_exist] : MoneyManager.default_zero_money
      branch_data_map[:fee_collectable] = loan_amounts_on_date[:fee_colleatable]
      branch_data_map[:ewi_collected] = loan_amounts_on_date[:scheduled_total_collected]
      branch_data_map[:overdue_ewi_collected] = loan_amounts_on_date[:overdue_received]
      branch_data_map[:fee_collected] = loan_amounts_on_date[:fee_colleated]
      branch_data_map[:advance_amount] = loan_amounts_on_date[:advance_received]
      branch_data_map[:other_fees_collected] = loan_amounts_on_date[:insurance_fee_collected]
      branch_data_map[:fore_closure_pos] = loan_amounts_on_date[:preclosure_pricipal]
      branch_data_map[:fore_closure_od_interest] = loan_amounts_on_date[:priclosure_interest]
      branch_data_map[:total_collections] = loan_amounts_on_date[:scheduled_total_collected] + loan_amounts_on_date[:overdue_received] + loan_amounts_on_date[:fee_colleated] + loan_amounts_on_date[:advance_received] + loan_amounts_on_date[:insurance_fee_collected] + loan_amounts_on_date[:preclosure_pricipal] + loan_amounts_on_date[:priclosure_interest]
      branch_data_map[:short_collections] = loan_amounts_on_date[:scheduled_total] > loan_amounts_on_date[:scheduled_total_collected] ? loan_amounts_on_date[:scheduled_total] - loan_amounts_on_date[:scheduled_total_collected] : MoneyManager.default_zero_money
      branch_data_map[:fee_differences] = loan_amounts_on_date[:fee_colleatable] > loan_amounts_on_date[:fee_colleated] ? loan_amounts_on_date[:fee_colleatable] - loan_amounts_on_date[:fee_colleated] : MoneyManager.default_zero_money

      data[:branches][branch_id] = branch_data_map
    }
    data
  end
end