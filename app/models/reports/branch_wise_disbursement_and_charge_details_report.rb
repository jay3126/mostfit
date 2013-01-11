class BranchWiseDisbursementAndChargeDetailsReport < Report

  attr_accessor :from_date, :to_date, :biz_location_branch_id

  def initialize(params, dates, user)
    @from_date = (dates and dates[:from_date]) ? dates[:from_date] : Date.today - 7
    @to_date   = (dates and dates[:to_date]) ? dates[:to_date] : Date.today
    @name = "Disbursement and Charge Details Report from #{@from_date} to #{@to_date}"
    @user = user
    location_facade = FacadeFactory.instance.get_instance(FacadeFactory::LOCATION_FACADE, @user)
    all_branch_ids = location_facade.all_nominal_branches.collect {|branch| branch.id}
    @biz_location_branch = (params and params[:biz_location_branch_id] and (not (params[:biz_location_branch_id].empty?))) ? params[:biz_location_branch_id] : all_branch_ids
    @page = params.blank? || params[:page].blank? ? 1 :params[:page]
    @limit = 10
    get_parameters(params, user)
  end

  def name
    "Disbursement and Charge Details Report for #{@from_date} to #{@to_date}"
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

    data = {}
    disbursal_dates = Lending.all(:disbursal_date.gte => @from_date, :disbursal_date.lte => @to_date ).aggregate(:disbursal_date)
    d_dates = disbursal_dates.to_a.paginate(:page => @page, :per_page => @limit)
    loan_products = LendingProduct.all.map(&:name)
    data[:loan_products] = loan_products
    data[:loan_info] = {}
    data[:disbursal_dates] = d_dates
    d_dates.each do |d_date|
      data[:loan_info][d_date] = {}
      loans = Lending.all(:fields => [:id, :disbursed_amount, :accounted_at_origin, :lending_product_id], :disbursal_date => d_date)
      loans.group_by{|l| l.accounted_at_origin}.each do |accounted_at_id, a_loans|
        branch = BizLocation.get accounted_at_id
        data[:loan_info][d_date][branch.name] = {}
        a_loans.group_by{|al| al.lending_product_id}.each do |loan_product_id, l_loans|
          loan_product = LendingProduct.get loan_product_id
          data[:loan_info][d_date][branch.name][loan_product.name] = {}
          data[:loan_info][d_date][branch.name][loan_product.name]['loans_count'] = l_loans.size
          data[:loan_info][d_date][branch.name][loan_product.name]['loans_amt_sum'] = MoneyManager.get_money_instance_least_terms(l_loans.map(&:disbursed_amount).sum.to_i)
          insurances = SimpleInsurancePolicy.all(:lending_id => l_loans.map(&:id))
          loan_fee_instance = FeeInstance.all(:fee_applied_on_type => :fee_on_loan, :fee_applied_on_type_id => l_loans.map(&:id))
          insurance_fee_instance = FeeInstance.all(:fee_applied_on_type => :fee_on_insurance, :fee_applied_on_type_id => insurances.map(&:id))

          loan_fee_amount = loan_fee_instance.blank? ? MoneyManager.default_zero_money : loan_fee_instance.map(&:total_money_amount).sum
          insurance_fee_amount = insurance_fee_instance.blank? ? MoneyManager.default_zero_money : insurance_fee_instance.map(&:total_money_amount).sum

          total_fee_colleable_on_date = loan_fee_amount + insurance_fee_amount
          loan_fee_receipts = FeeReceipt.all(:fee_applied_on_type => :fee_on_loan, :fee_applied_on_type_id => l_loans.map(&:id)).aggregate(:fee_amount.sum) rescue []
          insurance_fee_receipts = FeeReceipt.all(:fee_applied_on_type => :fee_on_insurance, :fee_applied_on_type_id => insurances.map(&:id)).aggregate(:fee_amount.sum) rescue []
          loan_fee_receipt_amount = loan_fee_receipts.blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance_least_terms(loan_fee_receipts.to_i)
          insurance_fee_receipt_amount = insurance_fee_receipts.blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance_least_terms(insurance_fee_receipts.to_i)
          total_fee_collected = loan_fee_receipt_amount + insurance_fee_receipt_amount
          data[:loan_info][d_date][branch.name][loan_product.name]['colleatable_fee'] = total_fee_colleable_on_date
          data[:loan_info][d_date][branch.name][loan_product.name]['colleated_fee'] = total_fee_collected

        end
      end
    end
    data
  end
end
