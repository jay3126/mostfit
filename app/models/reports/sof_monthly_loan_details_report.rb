class SofMonthlyLoanDetailsReport < Report
  attr_accessor :date, :funding_line_id, :page

  def initialize(params, dates, user)
    @date = dates[:date] || Date.today
    @status = params.blank? || params[:loan_active_status].blank? ? '' : params[:loan_active_status]
    @name = "SOF Monthly Loan Details Report from #{@date}"
    @user = user
    @page = params.blank? || params[:page].blank? ? 1 : params[:page]
    @limit = 100
    get_parameters(params, user)
  end

  def name
    "SOF Monthly Loan Details Report from #{@date}"
  end

  def self.name
    "SOF Monthly Loan Details Report"
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
    loan_ids = @funding_line_id.blank? ? [] : FundingLineAddition.all(:funding_line_id => @funding_line_id).aggregate(:lending_id)
    all_branches = BizLocation.all('location_level.level' => 1)
    branches = loan_ids.blank? ? [] : LoanAdministration.all(:loan_id => loan_ids).aggregate(:accounted_at)
    data[:branch_ids] = branches
    data[:record] = {}
    all_branches.each do |branch|
      scheduled_principal = scheduled_interest = scheduled_total = received_principal = received_interest = total_received = MoneyManager.default_zero_money
      processing_fee_on_date = preclose_fee_on_date = preclose_principal = disbursed_money_amt = pos_on_date = MoneyManager.default_zero_money
      branch_name = branch.name
      branch_id = branch.id
      if all_branches.map(&:id).include?(branch_id)
        branch_loans = LoanAdministration.get_loan_ids_group_vise_accounted_by_sql(branch_id, @date)
        disbursed_loan_ids = branch_loans[:disbursed_loan_status].blank? ? [] : branch_loans[:disbursed_loan_status]
        preclosure_loan_ids = branch_loans[:preclosed_loan_status].blank? ? [] : branch_loans[:preclosed_loan_status]
        disbursed_loan_ids = loan_ids & branch_loans[:disbursed_loan_status] unless @funding_line_id.blank?
        preclosure_loan_ids = loan_ids & branch_loans[:preclosed_loan_status] unless @funding_line_id.blank?
        total_loans = disbursed_loan_ids + preclosure_loan_ids
        loan_receipts = LoanReceipt.all(:lending_id => disbursed_loan_ids, :effective_on.lte => @date)
        preclose_loan_receipts = preclosure_loan_ids.blank? ? [] : LoanReceipt.all(:lending_id => preclosure_loan_ids)
        total_disbursed = disbursed_loan_ids.blank? ? [] : Lending.all(:id => disbursed_loan_ids).aggregate(:disbursed_amount.sum)
        total_disbured_amt = total_disbursed.blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance_least_terms(total_disbursed.to_i)
        loan_schedules = BaseScheduleLineItem.all( 'loan_base_schedule.lending_id' => total_loans, :on_date => @date)

        disbursed_amt =  disbursed_loan_ids.blank? ? [] : Lending.all(:disbursal_date => @date, :id => disbursed_loan_ids).aggregate(:disbursed_amount.sum)
        loan_fee = !preclosure_loan_ids.blank? && !disbursed_amt.blank? ? FeeReceipt.all_paid_loan_fee_receipts_on_accounted_at(branch_id, @date) : {:loan_fee_receipts =>[], :loan_preclousure_fee_receipts => []}
        processing_fee_receipt = loan_fee[:loan_fee_receipts].blank? ? [] : loan_fee[:loan_fee_receipts]
        preclose_fee_receipt = loan_fee[:loan_preclousure_fee_receipts].blank? ? [] : loan_fee[:loan_preclousure_fee_receipts]

        loan_schedules_on_date = loan_schedules.select{|s| s.on_date == @date}

        scheduled_principal = loan_schedules_on_date.blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance_least_terms(loan_schedules_on_date.map(&:scheduled_principal_due).sum.to_i)
        scheduled_interest = loan_schedules_on_date.blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance_least_terms(loan_schedules_on_date.map(&:scheduled_interest_due).sum.to_i)
        scheduled_total = scheduled_principal + scheduled_interest

        loan_receipt_on_date = loan_receipts.select{|s| s.effective_on == @date}
        preclose_loan_receipt_on_date = preclose_loan_receipts.select{|s| s.effective_on == @date}

        loan_receipt_amt_on_date = LoanReceipt.add_up(loan_receipt_on_date)
        preclose_loan_receipt_amt_on_date = LoanReceipt.add_up(preclose_loan_receipt_on_date)

        received_principal = loan_receipt_amt_on_date[:principal_received]
        received_interest = loan_receipt_amt_on_date[:interest_received]
        total_received = received_principal + received_interest

        preclose_principal = preclose_loan_receipt_amt_on_date[:principal_received]

        processing_fee_on_date = processing_fee_receipt.blank? ? MoneyManager.default_zero_money : processing_fee_receipt.map(&:fee_money_amount).sum
        preclose_fee_on_date = preclose_fee_receipt.blank? ? MoneyManager.default_zero_money : preclose_fee_receipt.map(&:fee_money_amount).sum

        total_collection = total_received + preclose_principal + processing_fee_on_date + preclose_fee_on_date
        disbursed_money_amt = disbursed_amt.blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance_least_terms(disbursed_amt.to_i)

        loan_receipts_amt_till_date = LoanReceipt.add_up(loan_receipts)
        principal_amt_till_date = loan_receipts_amt_till_date[:principal_received]

        pos_on_date = total_disbured_amt > principal_amt_till_date ? total_disbured_amt - principal_amt_till_date : MoneyManager.default_zero_money

      end

      data[:record][branch.id]= {
        :branch_name => branch_name, :branch_id => branch_id, :on_date => @date,
        :dues_emi_principal => scheduled_principal , :dues_emi_interest => scheduled_interest, :dues_emi_total => scheduled_total,
        :emi_collect_principal => received_principal, :emi_collect_interest => received_interest, :emi_collect_total => total_received,
        :loan_fee_collect => processing_fee_on_date, :preclosure_collect_fee => preclose_fee_on_date, :preclosure_collect => preclose_principal, :total_fee_collect => total_collection,
        :interest_accrued => scheduled_interest, :disbursed_amount => disbursed_money_amt, :outstanding_principal => pos_on_date
      }
    end
    data
  end

  def check_holiday_on_date(date)
    week_day = date.strftime('%A')
    return ['Saturday', 'Sunday'].include?(week_day)
  end

end
