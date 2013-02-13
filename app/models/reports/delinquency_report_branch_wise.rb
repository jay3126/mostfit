class DelinquencyReportBranchWise < Report
  attr_accessor :biz_location_branch_id, :date, :page, :file_format

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
    "Delinquency Report Branch Wise"
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
    at_branch_ids_ary = @biz_location_branch.is_a?(Array) ? @biz_location_branch : [@biz_location_branch]
    at_branch_ids_ary.each { |branch_id|
      branch                         = BizLocation.get branch_id
      loans                          = LoanAdministration.get_loan_ids_accounted_by_sql(branch_id, @date, false, 'disbursed_loan_status')

      overdue_pos_principal          = MoneyManager.default_zero_money
      total_overdue_amt              = MoneyManager.default_zero_money
      loan_disbursed_principal       = loans.blank? ? [] :  Lending.sum(:disbursed_amount, :id => loans)
      loan_disbursed_principal_amt   = loans.blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance_least_terms(loan_disbursed_principal.to_i)
      schedule_till_principal        = loans.blank? ? [] : BaseScheduleLineItem.sum(:scheduled_principal_due, 'loan_base_schedule.lending_id' => loans, :on_date.lte => @date)
      schedule_till_principal_amt    = schedule_till_principal.blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance_least_terms(schedule_till_principal.to_i)
      loan_outstanding_principal     = loan_disbursed_principal_amt - schedule_till_principal_amt

      loan_ids_overdues              = Lending.overdue_loans_for_location_on_date(branch, @date)
      overdue_loan_ids               = loan_ids_overdues.blank? ? [] : loan_ids_overdues
      unless overdue_loan_ids.blank?
        loan_principal_disbursed = Lending.sum(:disbursed_amount, :id => loan_ids_overdues)
        loan_receipts = LoanReceipt.all(:lending_id => loan_ids_overdues, :effective_on.lte => @date)
        loan_principal_receipts = loan_receipts.blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance_least_terms(loan_receipts.map(&:principal_received).sum.to_i)
        loan_interest_receipts = loan_receipts.blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance_least_terms(loan_receipts.map(&:interest_received).sum.to_i)
        loan_total_received = loan_principal_receipts + loan_interest_receipts
        loan_scheduled_till_date = BaseScheduleLineItem.all('loan_base_schedule.lending_id' => loan_ids_overdues, :on_date.lte => @date)
        loan_scheduled_principal_due_till_date = loan_scheduled_till_date.blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance_least_terms(loan_scheduled_till_date.map(&:scheduled_principal_due).sum.to_i)
        loan_scheduled_interest_due_till_date = loan_scheduled_till_date.blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance_least_terms(loan_scheduled_till_date.map(&:scheduled_interest_due).sum.to_i)
        loan_total_scheduled_due_till_date = loan_scheduled_principal_due_till_date + loan_scheduled_interest_due_till_date
        loan_principal_disbursed_amt = loan_principal_disbursed.blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance_least_terms(loan_principal_disbursed.to_i)
        total_overdue_amt = loan_principal_disbursed_amt > loan_principal_receipts ? loan_principal_disbursed_amt - loan_principal_receipts : MoneyManager.default_zero_money
        overdue_pos_principal = loan_total_scheduled_due_till_date > loan_total_received ? loan_total_scheduled_due_till_date - loan_total_received : MoneyManager.default_zero_money
      end
      if loan_outstanding_principal.amount > MoneyManager.default_zero_money.amount
        par_value = (overdue_pos_principal.amount.to_f)/(loan_outstanding_principal.amount.to_f)
        par = par_value.to_f*100
      else
        par = 0.0
      end
      
      branch_data_map                                    = {}
      branch_data_map[:branch_name]                      = branch.name
      branch_data_map[:loan_outstanding_principal]       = loan_outstanding_principal
      branch_data_map[:overdue_principal]                = total_overdue_amt
      branch_data_map[:loan_overdue]                     = overdue_pos_principal
      branch_data_map[:par]                              = par.round(2)

      data[branch_id]                                    = branch_data_map
    }
    data
  end

  def generate_xls
    name = @biz_location_branch.is_a?(Array) ? 'all_branches' : BizLocation.get(@biz_location_branch).name
    data = generate

    folder = File.join(Merb.root, "doc", "xls", "company",'reports', self.class.name.split(' ').join().downcase)
    FileUtils.mkdir_p(folder)
    csv_loan_file = File.join(folder, "deliquency_branch_wise_report_#{name}_#{@date.to_s}.csv")
    File.new(csv_loan_file, "w").close
    append_to_file_as_csv(headers, csv_loan_file)
    data.each do |location_id, s_value|
      value = [s_value[:branch_name], s_value[:loan_outstanding_principal], s_value[:overdue_principal], s_value[:loan_overdue], s_value[:par]]
      append_to_file_as_csv([value], csv_loan_file)
    end
    File.new(csv_loan_file, "w").close
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
    _headers ||= [["Branch Name", "POS", "OverDue","OverDue POS", "PAR(%)"]]
  end
end