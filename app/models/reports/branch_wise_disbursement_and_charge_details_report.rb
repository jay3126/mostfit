class BranchWiseDisbursementAndChargeDetailsReport < Report

  attr_accessor :from_date, :to_date, :biz_location_branch_id, :file_format

  def initialize(params, dates, user)
    @from_date = (dates and dates[:from_date]) ? dates[:from_date] : Date.today - 7
    @to_date   = (dates and dates[:to_date]) ? dates[:to_date] : Date.today
    @name = "Branch Wise Disbursement and Charge Details Report from #{@from_date} to #{@to_date}"
    @user = user
    location_facade = FacadeFactory.instance.get_instance(FacadeFactory::LOCATION_FACADE, @user)
    @biz_location_branch = (params and params[:biz_location_branch_id] and (not (params[:biz_location_branch_id].empty?))) ? params[:biz_location_branch_id] : ''
    @page = params.blank? || params[:page].blank? ? 1 :params[:page]
    @limit = 10
    get_parameters(params, user)
  end

  def name
    "Branch Wise Disbursement and Charge Details Report for #{@from_date} to #{@to_date}"
  end

  def self.name
    "Branch Wise Disbursement and Charge Details Report"
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
    if @biz_location_branch.blank?
      disbursed_loan_ids = Lending.total_loans_between_dates('disbursed_loan_status', @from_date, @to_date)
      disbursal_dates = disbursed_loan_ids.blank? ? [] : Lending.all(:id => disbursed_loan_ids, :disbursal_date.gte => @from_date, :disbursal_date.lte => @to_date).aggregate(:disbursal_date)
    else
      disbursed_loan_ids = LoanAdministration.get_loan_ids_accounted_for_date_range_by_sql(@biz_location_branch, @from_date, @to_date, false, 'disbursed_loan_status')
      disbursal_dates = disbursed_loan_ids.blank? ? [] : Lending.all(:id => disbursed_loan_ids, :disbursal_date.gte => @from_date, :disbursal_date.lte => @to_date).aggregate(:disbursal_date)
    end
    d_dates = disbursal_dates.to_a.paginate(:page => @page, :per_page => @limit)
    data[:loan_products] = []
    data[:loan_info] = {}
    data[:disbursal_dates] = d_dates
    d_dates.each do |d_date|
      data[:loan_info][d_date] = {}
      loans = Lending.all(:fields => [:id, :disbursed_amount, :accounted_at_origin, :lending_product_id], :disbursal_date => d_date, :id => disbursed_loan_ids)
      loans.group_by{|l| l.accounted_at_origin}.each do |accounted_at_id, a_loans|
        branch = BizLocation.get accounted_at_id
        data[:loan_info][d_date][branch.name] = {}
        a_loans.group_by{|al| al.lending_product_id}.each do |loan_product_id, l_loans|
          loan_product = LendingProduct.get loan_product_id
          data[:loan_products] << loan_product.name
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
    data[:loan_products].uniq!
    data
  end

  def generate_xls
    data = generate
    heading = ["Date", "Branch Name"]
    data[:loan_products].each do |product|
      heading << "Disb.(count)- "+product.to_s
    end
    heading << "Disb.(count)- Total"
    data[:loan_products].each do |product|
      heading << "Disb.(Amt)- "+product.to_s
    end
    heading << "Disb.(Amt)- Total"
    data[:loan_products].each do |product|
      heading << "Charges(colleatable)- "+product.to_s
    end
    heading << "Charges(colleatable)- Total"
    data[:loan_products].each do |product|
      heading << "Charges(colleated)- "+product.to_s
    end
    heading << "Charges(colleated)- Total"
    
    folder = File.join(Merb.root, "doc", "xls", "company",'reports', self.class.name.split(' ').join().downcase)
    FileUtils.mkdir_p(folder)
    csv_loan_file = File.join(folder, "disbursement_and_charge_details_report_From(#{@from_date.to_s})_To(#{@to_date.to_s}).csv")
    File.new(csv_loan_file, "w").close
    append_to_file_as_csv([heading], csv_loan_file)
    data[:loan_info].each do |date, b_values|
      b_values.each.each do |b_name, p_values|
        value = [date, b_name]
        l_count = 0
        data[:loan_products].each do |product|
          unless p_values[product].blank?
            l_count += p_values[product]['loans_count']
            value << p_values[product]['loans_count']
          end
        end
        value << l_count
        l_amt = MoneyManager.default_zero_money
        data[:loan_products].each do |product|
          unless p_values[product].blank?
            l_amt += p_values[product]['loans_amt_sum']
            value << p_values[product]['loans_amt_sum']
          end
        end
        value << l_amt

        fee_c = MoneyManager.default_zero_money
        data[:loan_products].each do |product|
          unless p_values[product].blank?
            fee_c += p_values[product]['colleatable_fee']
            value << p_values[product]['colleatable_fee']
          end
        end
        value << fee_c

        fee_r = MoneyManager.default_zero_money
        data[:loan_products].each do |product|
          unless p_values[product].blank?
            fee_r += p_values[product]['colleated_fee']
            value << p_values[product]['colleated_fee']
          end
        end
        value << fee_r
        append_to_file_as_csv([value], csv_loan_file)
      end
    end
    return true
  end

  def append_to_file_as_csv(data, filename)
    FasterCSV.open(filename, "a", {:col_sep => ","}) do |csv|
      data.each do |datum|
        csv << datum
      end
    end
  end

  def headers
    _headers ||= [["Date", "Branch Name", "Disb.", "Customer Name", "Loan Account Number", "Date", "Remarks", "Reason", "Foreclosure POS", "Foreclosure Interest", "Foreclosure Charges", "Broken period/unpaid intrest Collected"]]
  end
end
