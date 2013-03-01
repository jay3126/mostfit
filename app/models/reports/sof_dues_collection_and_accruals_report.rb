class SOFDuesCollectionAndAccrualsReport < Report

  attr_accessor :from_date, :to_date, :funding_line_id, :page, :file_format

  validates_with_method :funding_line_id, :funding_line_not_selected
  validates_with_method :method => :from_date_should_be_less_than_to_date

  def initialize(params, dates, user)
    @from_date = (dates && dates[:from_date]) ? dates[:from_date] : Date.today - 30
    @to_date   = (dates && dates[:to_date]) ? dates[:to_date] : Date.today
    @name = "SOF Dues Collection and Accrual Report from #{@from_date} to #{@to_date}"
    @user = user
    @page = params.blank? || params[:page].blank? ? 1 :params[:page]
    @limit = 10
    get_parameters(params, user)
  end

  def name
    "SOF Dues Collection and Accrual Report from #{@from_date} to #{@to_date}"
  end

  def self.name
    "SOF Dues Collection and Accrual Report"
  end

  def default_currency
    @default_currency = MoneyManager.get_default_currency
  end

  def generate
    data = {}
    loan_ids = FundingLineAddition.get_funder_loan_ids_by_sql(@funding_line_id, @to_date)
    branches = loan_ids.blank? ? [] : LoanAdministration.all(:loan_id => loan_ids).aggregate(:accounted_at).uniq.paginate(:page => @page, :per_page => @limit)
    data[:branch_ids] = branches
    data[:loans] = {}
    branches.each do |branch_id|
      branch             = BizLocation.get(branch_id)
      branch_loans = LoanAdministration.get_loan_ids_group_vise_accounted_for_date_range_by_sql(branch_id, @from_date, @to_date, @funding_line_id)
      disbursed_loan_ids = branch_loans[:disbursed_loan_status].blank? ? [] : branch_loans[:disbursed_loan_status]
      preclosure_loan_ids = branch_loans[:preclosed_loan_status].blank? ? [] : branch_loans[:preclosed_loan_status]
      repaid_loan_ids = branch_loans[:repaid_loan_status].blank? ? [] : branch_loans[:repaid_loan_status]
      write_off_loan_ids = branch_loans[:written_off_loan_status].blank? ? [] : branch_loans[:written_off_loan_status]
      total_loans = disbursed_loan_ids + repaid_loan_ids
      all_loans = disbursed_loan_ids + repaid_loan_ids + write_off_loan_ids + write_off_loan_ids
      d_schedules   = total_loans.blank? ? [] : BaseScheduleLineItem.all('loan_base_schedule.lending.id' => total_loans, :on_date.gte => @from_date, :on_date.lte => @to_date).aggregate(:scheduled_principal_due.sum, :scheduled_interest_due.sum) rescue []
      due_emi_principal = d_schedules.blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance_least_terms(d_schedules.first.to_i)
      due_emi_interest = d_schedules.blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance_least_terms(d_schedules.last.to_i)
      unless preclosure_loan_ids.blank?
        p_non_schedules = repository.adapter.query("select sum(scheduled_principal_due), sum(scheduled_interest_due) from base_schedule_line_items bl inner join loan_base_schedules lbs on lbs.id = bl.loan_base_schedule_id inner join lendings l on l.id = lbs.lending_id where bl.on_date >= '#{@from_date.strftime('%Y-%m-%d')}' and bl.on_date <= l.preclosed_on_date and l.id in (#{preclosure_loan_ids.join(',')});").first
        preclose_principal = p_non_schedules.blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance_least_terms(p_non_schedules.first.to_i)
        preclose_interest = p_non_schedules.blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance_least_terms(p_non_schedules.last.to_i)
        due_emi_principal += preclose_principal
        due_emi_interest += preclose_interest
      end
      unless write_off_loan_ids.blank?
        w_non_schedules = repository.adapter.query("select sum(scheduled_principal_due), sum(scheduled_interest_due) from base_schedule_line_items bl inner join loan_base_schedules lbs on lbs.id = bl.loan_base_schedule_id inner join lendings l on l.id = lbs.lending_id where bl.on_date >= '#{@from_date.strftime('%Y-%m-%d')}' and bl.on_date <= l.write_off_on_date and l.id in (#{write_off_loan_ids.join(',')});").first
        write_off_principal = w_non_schedules.blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance_least_terms(w_non_schedules.first.to_i)
        write_off_interest = w_non_schedules.blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance_least_terms(w_non_schedules.last.to_i)
        due_emi_principal += write_off_principal
        due_emi_interest += write_off_interest
      end
      t_dues_emi          = due_emi_principal + due_emi_interest

      loan_receipts         = LoanReceipt.all('payment_transaction.payment_towards'=>[Constants::Transaction::PAYMENT_TOWARDS_LOAN_REPAYMENT, Constants::Transaction::PAYMENT_TOWARDS_LOAN_RECOVERY], :lending_id => total_loans, :effective_on.gte => @from_date, :effective_on.lte => @to_date).aggregate(:principal_received.sum, :interest_received.sum, :advance_received.sum, :advance_adjusted.sum, :loan_recovery.sum)
      emi_collect_principal = loan_receipts[0].blank? ? MoneyManager.default_zero_money : Money.new(loan_receipts[0].to_i, default_currency)
      emi_collect_interest  = loan_receipts[1].blank? ? MoneyManager.default_zero_money : Money.new(loan_receipts[1].to_i, default_currency)
      emi_collect_total     = emi_collect_principal + emi_collect_interest
      advance_collection    = loan_receipts[2].blank? ? MoneyManager.default_zero_money : Money.new(loan_receipts[2].to_i, default_currency)
      recovery_collection    = loan_receipts[4].blank? ? MoneyManager.default_zero_money : Money.new(loan_receipts[4].to_i, default_currency)

      fee_collection         = FeeReceipt.all_paid_loan_fee_receipts_on_accounted_at_for_date_range(branch_id, @from_date, @to_date)
      fee_collect            = fee_collection[:loan_fee_receipts].blank? ? MoneyManager.default_zero_money : Money.new(fee_collection[:loan_fee_receipts].map(&:fee_amount).sum.to_i, default_currency)
      preclosure_fee_collect = fee_collection[:loan_preclousure_fee_receipts].blank? ? MoneyManager.default_zero_money : Money.new(fee_collection[:loan_preclousure_fee_receipts].map(&:fee_amount).sum.to_i, default_currency)

      preclosure_principal_collect = interest_accured = MoneyManager.default_zero_money

      preclose_receipts = preclosure_loan_ids.blank? ? [] : LoanReceipt.all('payment_transaction.payment_towards'=>Constants::Transaction::PAYMENT_TOWARDS_LOAN_PRECLOSURE, :lending_id => preclosure_loan_ids, :effective_on.gte => @from_date, :effective_on.lte => @to_date).aggregate(:principal_received.sum, :interest_received.sum)
      preclosure_principal_collect = preclose_receipts[0].blank? ? MoneyManager.default_zero_money : Money.new(preclose_receipts[0].to_i, default_currency)
      preclosure_interest_collect = preclose_receipts[0].blank? ? MoneyManager.default_zero_money : Money.new(preclose_receipts[1].to_i, default_currency)


      total_fee_collection      = emi_collect_total + fee_collect + preclosure_fee_collect + preclosure_principal_collect
      disbursed_loans_between   = all_loans.blank? ? [] : Lending.all(:id => all_loans, :disbursal_date.gte => @from_date, :disbursal_date.lte => @to_date).aggregate(:disbursed_amount.sum)
      disbursed_money_amt       = disbursed_loans_between.blank? ? MoneyManager.default_zero_money : Money.new(disbursed_loans_between.to_i, default_currency)
      total_disbursed_principal = disbursed_loan_ids.blank? ? MoneyManager.default_zero_money : Money.new(Lending.sum(:disbursed_amount, :id => disbursed_loan_ids).to_i, default_currency)
      loan_receipt_till_date    = disbursed_loan_ids.blank? ? [] : LoanReceipt.all(:lending_id => disbursed_loan_ids, :effective_on.lte => @to_date)
      principal_s_till_date     = disbursed_loan_ids.blank? ? [] : BaseScheduleLineItem.sum(:scheduled_principal_due, 'loan_base_schedule.lending_id' => disbursed_loan_ids, :on_date.lte => @to_date)
      principal_s_amount        = principal_s_till_date.blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance_least_terms(principal_s_amount.to_i)
      total_received_principal  = loan_receipt_till_date.blank? ? MoneyManager.default_zero_money : Money.new(loan_receipt_till_date.aggregate(:principal_received.sum).to_i, default_currency)
      outstanding_principal     = total_disbursed_principal > principal_s_amount ? total_disbursed_principal - principal_s_amount : MoneyManager.default_zero_money
      interest_accured          = due_emi_interest
      data[:loans][branch_id] = {
        :branch_name => branch.name, :branch_id => branch_id,
        :dues_emi_principal => due_emi_principal , :dues_emi_interest => due_emi_interest, :dues_emi_total => t_dues_emi,
        :emi_collect_principal => emi_collect_principal, :emi_collect_interest => emi_collect_interest, :emi_collect_total => emi_collect_total, :advance_collection => advance_collection, :recovery_collection => recovery_collection,
        :loan_fee_collect => fee_collect, :preclosure_collect_fee => preclosure_fee_collect, :preclosure_principal_collect => preclosure_principal_collect, :preclosure_interest_collect => preclosure_interest_collect, :preclosure_collect => (preclosure_interest_collect+preclosure_principal_collect),
        :total_fee_collect => total_fee_collection, :interest_accrued => interest_accured, :disbursed_amount => disbursed_money_amt,
        :outstanding_principal => outstanding_principal
      }
    end
    data
  end

  def funding_line_not_selected
    return [false, "Please select Funding Line"] if self.respond_to?(:funding_line_id) && !self.funding_line_id
    return true
  end

  def generate_xls
    @limit = 100
    data = generate

    folder = File.join(Merb.root, "doc", "xls", "company",'reports', self.class.name.split(' ').join().downcase)
    FileUtils.mkdir_p(folder)
    csv_loan_file = File.join(folder, "sof_dues_collection_and_accruals_report_From(#{@from_date.to_s})_To(#{@to_date.to_s}).csv")
    File.new(csv_loan_file, "w").close
    append_to_file_as_csv(headers, csv_loan_file)
    data[:loans].each do |location_id, s_value|
      total = s_value[:emi_collect_total] + s_value[:advance_collection] + s_value[:recovery_collection] + s_value[:loan_fee_collect] + s_value[:preclosure_collect_fee] + s_value[:preclosure_collect]
      value = [s_value[:branch_name], s_value[:dues_emi_principal], s_value[:dues_emi_interest], s_value[:dues_emi_total], s_value[:emi_collect_principal], s_value[:emi_collect_interest], s_value[:emi_collect_total], s_value[:advance_collection], s_value[:recovery_collection],
        s_value[:loan_fee_collect], s_value[:preclosure_principal_collect], s_value[:preclosure_interest_collect], s_value[:preclosure_collect_fee],total, s_value[:interest_accrued], s_value[:disbursed_amount], s_value[:outstanding_principal]
      ]
      append_to_file_as_csv([value], csv_loan_file)
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
    _headers ||= [["Branch Name", "EWI Principal", "EWI Interest","EWI Total", "EWI Principal Collected", "EWI Interest Collected", "EWI Total Collected", "Advance Collected", "Recovery Collected", "Processing Fee", "Foreclosure Principal", "Foreclosure Interest", "Foreclosure Fee", "Total Collection", "Interest Accrued", "Disbursment", "POS"]]
  end
end