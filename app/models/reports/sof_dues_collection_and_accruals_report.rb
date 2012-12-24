class SOFDuesCollectionAndAccrualsReport < Report

  attr_accessor :from_date, :to_date, :funding_line_id, :page

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
    loan_ids = FundingLineAddition.all(:funding_line_id => @funding_line_id).aggregate(:lending_id)
    branches = loan_ids.blank? ? [] : LoanAdministration.all(:loan_id => loan_ids).aggregate(:accounted_at).uniq.paginate(:page => @page, :per_page => @limit)
    data[:branch_ids] = branches
    data[:loans] = {}
    branches.each do |branch_id|
      branch             = BizLocation.get(branch_id)
      all_loans          = LoanAdministration.get_loans_accounted_by_sql(branch_id, @to_date)
      disbursed_loans    = LoanAdministration.get_loans_accounted_by_sql(branch_id, @to_date, false,'disbursed_loan_status')
      remaining_loans    = all_loans - disbursed_loans
      remaining_amounts  = remaining_loans.blank? ? [] : repository.adapter.query("SELECT SUM(scheduled_principal_due) AS principal, SUM(scheduled_interest_due) AS interest FROM base_schedule_line_items INNER JOIN loan_base_schedules ON base_schedule_line_items.loan_base_schedule_id = loan_base_schedules.id INNER JOIN lendings ON loan_base_schedules.lending_id = lendings.id WHERE lendings.id = (select lending_id from loan_status_changes where from_status = 5 and lending_id = lendings.id) AND on_date <= (select effective_on from loan_status_changes where from_status = 5 and lending_id = lendings.id) AND lendings.id IN (#{remaining_loans.map(&:id).join(',')}) AND on_date >= '#{@from_date.strftime("%Y-%m-%d")}';")
      schedules          = BaseScheduleLineItem.all('loan_base_schedule.lending.id' => disbursed_loans.map(&:id), :on_date.gte => @from_date, :on_date.lte => @to_date)
      scheduled_amounts  = schedules.blank? ? [] : schedules.aggregate(:scheduled_principal_due.sum, :scheduled_interest_due.sum)
      dues_emi_principal = scheduled_amounts[0].blank? ? MoneyManager.default_zero_money : Money.new(scheduled_amounts[0].to_i, default_currency)
      dues_emi_interest  = scheduled_amounts[1].blank? ? MoneyManager.default_zero_money : Money.new(scheduled_amounts[1].to_i, default_currency)
      remain_emi_principal = remaining_amounts.blank? ? MoneyManager.default_zero_money : Money.new(remaining_amounts.first.principal.to_i, default_currency)
      remain_emi_interest  = remaining_amounts.blank? ? MoneyManager.default_zero_money : Money.new(remaining_amounts.first.interest.to_i, default_currency)
      t_due_emi_principal = dues_emi_principal + remain_emi_principal
      t_due_emi_interest  = dues_emi_interest + remain_emi_interest
      t_dues_emi          = t_due_emi_principal + t_due_emi_interest

      loan_receipts         = LoanReceipt.all('payment_transaction.payment_towards'=>Constants::Transaction::PAYMENT_TOWARDS_LOAN_REPAYMENT, :accounted_at => branch_id, :effective_on.gte => @from_date, :effective_on.lte => @to_date).aggregate(:principal_received.sum, :interest_received.sum, :advance_received.sum, :advance_adjusted.sum, :loan_recovery.sum)
      emi_collect_principal = loan_receipts[0].blank? ? MoneyManager.default_zero_money : Money.new(loan_receipts[0].to_i, default_currency)
      emi_collect_interest  = loan_receipts[1].blank? ? MoneyManager.default_zero_money : Money.new(loan_receipts[1].to_i, default_currency)
      emi_collect_total     = emi_collect_principal + emi_collect_interest

      fee_collection         = FeeReceipt.all_paid_loan_fee_receipts_on_accounted_at_for_date_range(branch_id, @from_date, @to_date)
      fee_collect            = fee_collection[:loan_fee_receipts].blank? ? MoneyManager.default_zero_money : Money.new(fee_collection[:loan_fee_receipts].map(&:fee_amount).sum.to_i, default_currency)
      preclosure_fee_collect = fee_collection[:loan_preclousure_fee_receipts].blank? ? MoneyManager.default_zero_money : Money.new(fee_collection[:loan_preclousure_fee_receipts].map(&:fee_amount).sum.to_i, default_currency)

      preclose_loans               = LoanAdministration.get_loans_accounted_by_sql(branch_id, @to_date, false,'preclosed_loan_status')
      preclose_loan                = preclose_loans.blank? ? [0] : Lending.all(:id => preclose_loans.map(&:id), :preclosed_on_date.gte => @from_date, :preclosed_on_date.lte => @to_date)
      preclosure_principal_collect = interest_accured = MoneyManager.default_zero_money
      
      preclose_receipts = preclose_loan.blank? ? [] : LoanReceipt.all('payment_transaction.payment_towards'=>Constants::Transaction::PAYMENT_TOWARDS_LOAN_PRECLOSURE, :lending_id => preclose_loan.map(&:id)).aggregate(:principal_received.sum, :interest_received.sum)
      preclosure_principal_collect = preclose_receipts[0].blank? ? MoneyManager.default_zero_money : Money.new(preclose_receipts[0].to_i, default_currency)


      total_fee_collection      = emi_collect_total + fee_collect + preclosure_fee_collect + preclosure_principal_collect
      disbursed_loans_between   = Lending.all(:id => disbursed_loans.map(&:id), :disbursal_date.gte => @from_date, :disbursal_date.lte => @to_date)
      disbursed_amt             = disbursed_loans_between.blank? ? 0 : disbursed_loans_between.aggregate(:disbursed_amount.sum)
      disbursed_money_amt       = disbursed_amt.to_i < 0 ? MoneyManager.default_zero_money : Money.new(disbursed_amt.to_i, default_currency)
      total_disbursed_principal = disbursed_loans.blank? ? MoneyManager.default_zero_money : Money.new(disbursed_loans.map(&:disbursed_amount).sum.to_i, default_currency)
      loan_receipt_till_date    = disbursed_loans.blank? ? [] : LoanReceipt.all(:lending_id => disbursed_loans.map(&:id), :effective_on.lte => @to_date)
      total_received_principal  = loan_receipt_till_date.blank? ? MoneyManager.default_zero_money : Money.new(loan_receipt_till_date.aggregate(:principal_received.sum).to_i, default_currency)
      outstanding_principal     = total_disbursed_principal - total_received_principal
      interest_accured          = t_due_emi_interest
      data[:loans][branch_id] = {
        :branch_name => branch.name, :branch_id => branch_id,
        :dues_emi_principal => t_due_emi_principal , :dues_emi_interest => t_due_emi_interest, :dues_emi_total => t_dues_emi,
        :emi_collect_principal => emi_collect_principal, :emi_collect_interest => emi_collect_interest, :emi_collect_total => emi_collect_total,
        :loan_fee_collect => fee_collect, :preclosure_collect_fee => preclosure_fee_collect, :preclosure_collect => preclosure_principal_collect,
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
end