class PreClosureCustomerDetails < Report
  attr_accessor :from_date, :to_date, :file_format

  def initialize(params, dates, user)
    @from_date = (dates and dates[:from_date]) ? dates[:from_date] : Date.today - 7
    @to_date   = (dates and dates[:to_date]) ? dates[:to_date] : Date.today
    @name = "Consolidated Report from #{@from_date} to #{@to_date}"
    @user = user
    get_parameters(params, user)
  end

  def name
    "Pre-Closure Customer Details Report from #{@from_date} to #{@to_date}"
  end

  def self.name
    "Pre Closure Customer Details "
  end

  def default_currency
    @default_currency = MoneyManager.get_default_currency
  end

  def generate

    data = {}
    lendings = LoanStatusChange.status_between_dates(LoanLifeCycle::PRECLOSED_LOAN_STATUS, @from_date, @to_date).lending
    lendings.each do |loan|
      member                    = loan.loan_borrower.counterparty
      status_date               = loan.preclosed_on_date
      comment                   = Comment.last(:commentable_class => 'Lending', :commentable_id => loan.id, :created_on => loan.preclosed_on_date)
      remarks                   = comment.blank? ? '' : comment.text rescue ''
      reason                    = comment.blank? ? '' : Reason.get(comment.reason_id).name rescue ''
      loan_receipts             = loan.loan_receipts
      pre_closure_receipts      = loan.loan_receipts('payment_transaction.payment_towards' => Constants::Transaction::PAYMENT_TOWARDS_LOAN_PRECLOSURE)
      pre_closure_amt           = LoanReceipt.add_up(pre_closure_receipts)
      pre_closure_principal     = pre_closure_amt[:principal_received]
      pre_closure_interest      = pre_closure_amt[:interest_received]
      p_loan_receipts           = loan_receipts - pre_closure_receipts
      p_loan_amt                = LoanReceipt.add_up(p_loan_receipts)
      schedules                 = loan.loan_base_schedule.base_schedule_line_items(:on_date.lte => loan.preclosed_on_date).aggregate(:scheduled_principal_due.sum, :scheduled_interest_due.sum) rescue []
      s_principal               = schedules.blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance_least_terms(schedules[0].to_i)
      s_interest                = schedules.blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance_least_terms(schedules[1].to_i)
      overdue_principal         = s_principal > p_loan_amt[:principal_received] ? s_principal - p_loan_amt[:principal_received] : MoneyManager.default_zero_money
      overdue_interest          = s_interest > p_loan_amt[:interest_received] ? s_interest - p_loan_amt[:interest_received] : MoneyManager.default_zero_money
      broken_interest           = loan.schedule_date?(loan.preclosed_on_date) ? MoneyManager.default_zero_money : loan.broken_period_interest_due(loan.preclosed_on_date)
      total_preclosure_int      = overdue_interest + broken_interest
      fee_instances             = FeeInstance.unpaid_loan_preclosure_fee_instance(loan.id)
      fee_receipts              = fee_instances.blank? ? '' : fee_instances.fee_receipt.to_money[:fee_amount] unless
      pre_closure_charges       = fee_receipts.blank? ? MoneyManager.default_zero_money : fee_receipts.sum
      pre_closure_other_charges = MoneyManager.default_zero_money
      loan_account_number       = loan.lan
      member_name               = member ? member.name : "Not Specified"
      center                    = loan.administered_at_origin_location
      center_id                 = center ? center.id : "Not Specified"
      center_name               = center ? center.name : "Not Specified"
      branch                    = loan.accounted_at_origin_location
      branch_name               = branch ? branch.name : "Not Specified"
      branch_id                 = branch ? branch.id : "Not Specified"

      data[loan.id] = {:member_name => member_name, :center_name => center_name, :center_id => center_id,
        :branch_name => branch_name, :branch_id => branch_id,
        :on_date => status_date, :remarks => remarks, :reason => reason,
        :pre_closure_principal_amount => pre_closure_principal, :pre_closure_interest_amount => pre_closure_interest, :pre_closure_charges => pre_closure_charges, :pre_closure_other_charges => pre_closure_other_charges,
        :loan_account_number => loan_account_number, :pre_closure_total_interest_accrued => total_preclosure_int }
    end
    data
  end

  def generate_xls
    data = generate

    folder = File.join(Merb.root, "doc", "xls", "company",'reports', self.class.name.split(' ').join().downcase)
    FileUtils.mkdir_p(folder)
    csv_loan_file = File.join(folder, "pre_clousure_report_From(#{@from_date.to_s})_To(#{@to_date.to_s}).csv")
    File.new(csv_loan_file, "w").close
    append_to_file_as_csv(headers, csv_loan_file)
    data.each do |loan_id, s_value|
      value = [s_value[:branch_name], s_value[:center_name], s_value[:member_name], s_value[:loan_account_number], s_value[:on_date], s_value[:remarks], s_value[:reason], s_value[:pre_closure_principal_amount],
        s_value[:pre_closure_interest_amount], s_value[:pre_closure_charges], s_value[:pre_closure_total_interest_accrued]]
      append_to_file_as_csv([value], csv_loan_file)
    end
    return true
  end

  def append_to_file_as_csv(data, filename)
    FasterCSV.open(filename, "a", {:col_sep => "|"}) do |csv|
      data.each do |datum|
        csv << datum
      end
    end
  end

  def headers
    _headers ||= [["Branch Name", "Center Name", "Customer Name", "Loan Account Number", "Date", "Remarks", "Reason", "Foreclosure POS", "Foreclosure Interest", "Foreclosure Charges", "Broken period/unpaid intrest Collected"]]
  end
end
