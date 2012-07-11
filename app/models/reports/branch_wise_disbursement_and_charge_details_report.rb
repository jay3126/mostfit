class BranchWiseDisbursementAndChargeDetailsReport < Report

  attr_accessor :date, :biz_location_branch, :lending_product_id

  def initialize(params, dates, user)
    @date = (dates and dates[:date]) ? dates[:date] : Date.today
    @name = "Disbursement and Charge Details Report"
    @user = user
    location_facade = get_location_facade(@user)
    all_branch_ids = location_facade.all_nominal_branches.collect {|branch| branch.id}
    @biz_location_branch = (params and params[:biz_location_branch] and (not (params[:biz_location_branch].empty?))) ? params[:biz_location_branch] : all_branch_ids
    @lending_product_id = (params and params[:lending_rpoduct_id] and (not (params[:lending_product_id].empty?))) ? params[:lending_product_id] : LendingProduct.all.map{|lp| lp.id}
    get_parameters(params, user)
  end

  def name
    "Disbursement and Charge Details Report for #{@date}"
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

    lending_product = @lending_product_id.is_a?(Array) ? @lending_product_id : [@lending_product_id]

    at_branch_ids_ary = @biz_location_branch.is_a?(Array) ? @biz_location_branch : [@biz_location_branch]
    at_branch_ids_ary.each do |branch_id|

      loan_disbursals = reporting_facade.loans_disbursed_by_branches_on_date(@date, *branch_id)
      fee_receipts = reporting_facade.aggregate_fee_receipts_on_loans_by_branches(@date, @date, *branch_id)

      branch_data_map = {}
      branch_data_map[:loan_disbursals] = loan_disbursals
      branch_data_map[:fee_receipts] = fee_receipts
      data[branch_id] = branch_data_map
    end
    data
  end
end
