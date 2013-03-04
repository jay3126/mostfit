class BranchDateWiseDcaReport < Report
  attr_accessor :from_date, :to_date, :biz_location_branch_id, :file_format

  def initialize(params, dates, user)
    @from_date = (dates and dates[:from_date]) ? dates[:from_date] : Date.today - 7
    @to_date   = (dates and dates[:to_date]) ? dates[:to_date] : Date.today
    @name = "Branch Date Wise DCA Report from #{@from_date} to #{@to_date}"
    @user = user
    @biz_location_branch = (params and params[:biz_location_branch_id] and (not (params[:biz_location_branch_id].empty?))) ? params[:biz_location_branch_id] : nil
    @page = params.blank? || params[:page].blank? ? 1 :params[:page]
    @limit = 10
    get_parameters(params, user)
  end

  def name
    "Branch Date Wise DCA Report from #{@from_date} to #{@to_date}"
  end

  def self.name
    "Branch Date Wise DCA Report"
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
    location_facade = get_location_facade(@user)
    branches  = @biz_location_branch.blank? ? location_facade.all_nominal_branches.collect {|branch| branch.id} : @biz_location_branch
    branches  = BizLocation.all(:fields => [:id, :name], :id => branches)
    data[:branches] = branches.map(&:id).to_a.paginate(:page => @page, :per_page => @limit)
    data[:record] = {}

    data[:branches].each do |branch_id|
      branch = BizLocation.get branch_id
      branch_name = branch.name
      branch_loans = LoanAdministration.get_loan_ids_group_vise_accounted_for_date_range_by_sql(branch_id, @from_date, @to_date)
      disbursed_loan_ids = branch_loans[:disbursed_loan_status].blank? ? [] : branch_loans[:disbursed_loan_status]
      preclosure_loan_ids = branch_loans[:preclosed_loan_status].blank? ? [] : branch_loans[:preclosed_loan_status]
      repaid_loan_ids = branch_loans[:repaid_loan_status].blank? ? [] : branch_loans[:repaid_loan_status]
      total_loans = disbursed_loan_ids + repaid_loan_ids
      loan_receipts = LoanReceipt.all(:is_advance_adjusted => false, :accounted_at => branch_id, 'payment_transaction.payment_towards' => Constants::Transaction::PAYMENT_TOWARD_FOR_REPAYMENT, :effective_on.lte => @to_date)
      preclose_loan_receipts = LoanReceipt.all(:is_advance_adjusted => false, :accounted_at => branch_id, 'payment_transaction.payment_towards' => Constants::Transaction::PAYMENT_TOWARDS_LOAN_PRECLOSURE, :effective_on.lte => @to_date)
      disbursment_loans = PaymentTransaction.all(:accounted_at => branch_id, :payment_towards => Constants::Transaction::PAYMENT_TOWARDS_LOAN_DISBURSEMENT, :effective_on.gte => @from_date, :effective_on.lte => @to_date)
      total_disbursed = total_loans.blank? ? [] : Lending.sum(:disbursed_amount, :id => total_loans)
      total_disbured_amt = total_disbursed.blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance_least_terms(total_disbursed.to_i)
      loan_schedules = BaseScheduleLineItem.all('loan_base_schedule.lending_id' => total_loans,:on_date.gte => @from_date, :on_date.lte => @to_date)
      loan_fee = FeeReceipt.all_paid_loan_fee_receipts_on_accounted_at_for_date_range(branch_id, @from_date, @to_date)
      p_loans = preclosure_loan_ids.blank? ? [] : Lending.all(:fields => [:id,:preclosed_on_date], :id => preclosure_loan_ids)
      p_loans_schedules = p_loans.blank? ? [] : p_loans.loan_base_schedule.base_schedule_line_items(:on_date.lte => @to_date)
      process_fee = loan_fee[:loan_fee_receipts].blank? ? [] : loan_fee[:loan_fee_receipts]
      preclose_fee = loan_fee[:loan_preclousure_fee_receipts].blank? ? [] : loan_fee[:loan_preclousure_fee_receipts]

      data[:record][branch_id] = {}
      (@from_date..@to_date).each do |on_date|
        data[:record][branch_id][on_date] = {}
        schedules_on_date = loan_schedules.select{|s| s.on_date == on_date}
        if preclosure_loan_ids.blank?
          preclose_schedules = []
        else
          p_loans_after_on_date = p_loans.select{|s| s.preclosed_on_date >= on_date}
          preclose_schedules = p_loans_after_on_date.blank? ? [] : p_loans_schedules.select{|s| s.on_date == on_date && p_loans_after_on_date.map(&:id).include?(s.loan_base_schedule.lending_id)}
        end
        loan_schedules_on_date = schedules_on_date + preclose_schedules
        scheduled_principal = loan_schedules_on_date.blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance_least_terms(loan_schedules_on_date.map(&:scheduled_principal_due).sum.to_i)
        scheduled_interest = loan_schedules_on_date.blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance_least_terms(loan_schedules_on_date.map(&:scheduled_interest_due).sum.to_i)
        scheduled_total = scheduled_principal + scheduled_interest

        loan_receipt_on_date = loan_receipts.to_a.select{|s| s.effective_on == on_date}

        preclose_loan_receipt_on_date = preclose_loan_receipts.blank? ? [] : preclose_loan_receipts.to_a.select{|s| s.effective_on == on_date}

        received_principal = loan_receipt_on_date.blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance_least_terms(loan_receipt_on_date.map(&:principal_received).sum.to_i)
        received_interest = loan_receipt_on_date.blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance_least_terms(loan_receipt_on_date.map(&:interest_received).sum.to_i)
        received_advance = loan_receipt_on_date.blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance_least_terms(loan_receipt_on_date.map(&:advance_received).sum.to_i)
        received_recovery = loan_receipt_on_date.blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance_least_terms(loan_receipt_on_date.map(&:loan_recovery).sum.to_i)
        total_received = received_principal + received_interest

        preclose_principal = preclose_loan_receipt_on_date.blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance_least_terms(preclose_loan_receipt_on_date.map(&:principal_received).sum.to_i)
        preclose_interest = preclose_loan_receipt_on_date.blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance_least_terms(preclose_loan_receipt_on_date.map(&:interest_received).sum.to_i)

        processing_fee_receipt = process_fee.blank? ? [] : process_fee.select{|s| s.effective_on == on_date}
        preclose_fee_receipt = preclose_fee.blank? ? [] : preclose_fee.select{|s| s.effective_on == on_date}
        processing_fee_on_date = processing_fee_receipt.blank? ? MoneyManager.default_zero_money : processing_fee_receipt.map(&:fee_money_amount).sum
        preclose_fee_on_date = preclose_fee_receipt.blank? ? MoneyManager.default_zero_money : preclose_fee_receipt.map(&:fee_money_amount).sum

        total_collection = total_received + preclose_principal + processing_fee_on_date + preclose_fee_on_date
        d_loans = disbursment_loans.blank? ? [] : disbursment_loans.select{|s| s.effective_on == on_date}
        disbursed_money_amt = d_loans.blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance_least_terms(d_loans.map(&:amount).sum.to_i)
        schedule_principal_till_date = total_loans.blank? ? [] : BaseScheduleLineItem.sum(:scheduled_principal_due, 'loan_base_schedule.lending_id' => total_loans, :on_date.lte => on_date)
        schedule_principal_till_date_amt = schedule_principal_till_date.blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance_least_terms(schedule_principal_till_date.to_i)
        pos_on_date = total_disbured_amt > schedule_principal_till_date_amt ? total_disbured_amt - schedule_principal_till_date_amt : MoneyManager.default_zero_money
        interest_between_dates_amt = reverse_interest_amt = broken_interest_amt = interest_accrued = MoneyManager.default_zero_money
        interest_accrued = scheduled_interest
        if Constants::Time.is_last_day_of_month?(on_date)
          reverse_interest = AccrualTransaction.sum(:amount, :accrual_temporal_type => :reverse_broken_period_accrual, :effective_on.lte => @to_date, :effective_on.gte => @from_date, :accounted_at => branch_id)
          reverse_interest_amt = reverse_interest.blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance_least_terms(reverse_interest.to_i)
          broken_interest = AccrualTransaction.sum(:amount, :accrual_temporal_type => :accrue_broken_period, :effective_on => on_date, :accounted_at => branch_id)
          broken_interest_amt = broken_interest.blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance_least_terms(broken_interest.to_i)
          interest_between_dates = AccrualTransaction.sum(:amount, :accrual_allocation_type => :accrue_interest_allocation, :accrual_temporal_type => :accrue_regular, :effective_on.gte => @from_date, :effective_on.lte => @to_date, :accounted_at => branch_id)
          interest_between_dates_amt = interest_between_dates.blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance_least_terms(interest_between_dates.to_i)
        end
        data[:record][branch_id][on_date] = {
          :branch_name => branch_name, :branch_id => branch_id, :on_date => on_date,
          :dues_emi_principal => scheduled_principal , :dues_emi_interest => scheduled_interest, :dues_emi_total => scheduled_total,
          :emi_collect_principal => received_principal, :emi_collect_interest => received_interest, :emi_collect_total => total_received,
          :loan_fee_collect => processing_fee_on_date, :preclosure_collect_fee => preclose_fee_on_date, :preclosure_principal => preclose_principal, :preclosure_interest => preclose_interest, :total_fee_collect => total_collection,
          :interest_accrued => interest_accrued, :disbursed_amount => disbursed_money_amt, :outstanding_principal => pos_on_date, :advance_received => received_advance, :loan_recovery => received_recovery,
          :interest_between_dates_amt => interest_between_dates_amt, :reverse_interest_amt => reverse_interest_amt, :broken_interest_amt => broken_interest_amt
        }
      end
    end
    data
  end


  def generate_xls
    @limit = 100
    name = @biz_location_branch.blank? ? 'all_branches' : BizLocation.get(@biz_location_branch).name
    data = generate

    folder = File.join(Merb.root, "doc", "xls", "company",'reports', self.class.name.split(' ').join().downcase)
    FileUtils.mkdir_p(folder)
    csv_loan_file = File.join(folder, "branch_date_wise_dca_report_#{name}_From(#{@from_date.to_s})_To(#{@to_date.to_s}).csv")
    File.new(csv_loan_file, "w").close
    append_to_file_as_csv(headers, csv_loan_file)
    data[:record].each do |location__id, location_values|
      location_values.each do |date, s_value|
        total_collcection = s_value[:emi_collect_total] + s_value[:advance_received] + s_value[:loan_recovery] + s_value[:loan_fee_collect] + s_value[:preclosure_principal] + s_value[:preclosure_interest] + s_value[:preclosure_collect_fee]
        value = [s_value[:branch_name], s_value[:on_date], s_value[:dues_emi_principal], s_value[:dues_emi_interest], s_value[:dues_emi_total], s_value[:emi_collect_principal], s_value[:emi_collect_interest], s_value[:emi_collect_total],
          s_value[:advance_received],s_value[:loan_recovery], s_value[:loan_fee_collect], s_value[:preclosure_principal], s_value[:preclosure_interest], s_value[:preclosure_collect_fee], total_collcection, s_value[:interest_accrued], s_value[:disbursed_amount], s_value[:outstanding_principal]
        ]
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
    _headers ||= [["Branch Name", "Txn Date", "EMI Principal Due", "EMI Interest Due", "EMI Total", "EMI Principal Collceted", "EMI Interest Collected", "EMI Total Collected", "Advance Amt","Recovey Amt","Processing Fee",  "Foreclosure POS", "Foreclosure Interest", "Foreclosure Fee", "Total Collected", "Interest Accrued", "Disbursed Amount", "POS"]]
  end

  def check_holiday_on_date(date)
    week_day = date.strftime('%A')
    return ['Saturday', 'Sunday'].include?(week_day)
  end

end
