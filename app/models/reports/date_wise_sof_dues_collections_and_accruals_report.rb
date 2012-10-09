class DateWiseSofDuesCollectionsAndAccrualsReport < Report
  attr_accessor :from_date, :to_date

  def initialize(params, dates, user)
    @from_date = (dates and dates[:from_date]) ? dates[:from_date] : Date.today - 7
    @to_date   = (dates and dates[:to_date]) ? dates[:to_date] : Date.today
    @name = "Date Wise SOF Dues Collections and Accruals Report from #{@from_date} to #{@to_date}"
    @user = user
    get_parameters(params, user)
  end

  def name
    "Date Wise SOF Dues Collections and Accruals Report from #{@from_date} to #{@to_date}"
  end

  def self.name
    "Date Wise SOF Dues Collections and Accruals Report"
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

    all_branches = location_facade.all_nominal_branches
    preclosure_loans = LoanStatusChange.status_between_dates(LoanLifeCycle::REPAID_LOAN_STATUS, @from_date, @to_date).lending    

    (@from_date..@to_date).each do |on_date|
      unless check_holiday_on_date(on_date)
        preclosure_collect = interest_accured = disbursed_amount = outstanding_principal = emi_collect_interest = MoneyManager.default_zero_money
        dues_emi_interest  = dues_emi_total = dues_emi_principal = emi_collect_principal = emi_collect_total = MoneyManager.default_zero_money
        fee_collect        = total_fee_collection = preclosure_fee_collect = MoneyManager.default_zero_money
        data[on_date] = {}

        all_branches.each do |branch|
          branch_name = branch.name
          branch_id = branch.id          
          branch_loans = LoanAdministration.get_loans_accounted(branch_id, on_date).compact
          branch_preclosure_loans = branch_loans & preclosure_loans
          branch_loans.each do |loan|
            if loan.is_outstanding_on_date?(on_date)
              dues_emi_principal    += loan.actual_principal_outstanding(on_date) || MoneyManager.default_zero_money
              dues_emi_interest     += loan.actual_interest_outstanding(on_date)  || MoneyManager.default_zero_money
              dues_emi_total        = dues_emi_principal + dues_emi_interest
              emi_collect_principal += loan.principal_received_on_date(on_date)
              emi_collect_interest  += loan.interest_received_on_date(on_date)
              emi_collect_total     = emi_collect_principal + emi_collect_interest
              interest_accured      = interest_accured      + loan.accrued_interim_interest(@from_date, @to_date)
              disbursed_amount      = disbursed_amount      + loan.to_money[:disbursed_amount] if loan.disbursal_date == on_date
              outstanding_principal = outstanding_principal + loan.actual_principal_outstanding(on_date)
            end
          end
          
          fee_collection         = FeeReceipt.all_paid_loan_fee_receipts_on_accounted_at(branch_id, on_date)
          fee_collect            = fee_collection[:loan_fee_receipts].blank? ? MoneyManager.default_zero_money  : Money.new(fee_collection[:loan_fee_receipts].map(&:fee_amount).sum.to_i, default_currency)
          preclosure_fee_collect = fee_collection[:loan_preclousure_fee_receipts].blank? ? MoneyManager.default_zero_money  : Money.new(fee_collection[:loan_preclousure_fee_receipts].map(&:fee_amount).sum.to_i, default_currency)

          branch_preclosure_loans.each do |lending|
            status_change      = lending.loan_status_changes(:to_status => LoanLifeCycle::REPAID_LOAN_STATUS, :effective_on => on_date)
            preclosure_collect += lending.loan_receipts.last.to_money[:principal_received] unless status_change.blank?
          end

          total_fee_collection = fee_collect + preclosure_fee_collect + preclosure_collect
        
          data[on_date][branch_id] = {
            :on_date => on_date, :branch_name => branch_name, :branch_id => branch_id,
            :dues_emi_principal => dues_emi_principal , :dues_emi_interest => dues_emi_interest, :dues_emi_total => dues_emi_total,
            :emi_collect_principal => emi_collect_principal, :emi_collect_interest => emi_collect_interest, :emi_collect_total => emi_collect_total,
            :loan_fee_collect => fee_collect, :preclosure_collect_fee => preclosure_fee_collect, :preclosure_collect => preclosure_collect, :total_fee_collect => total_fee_collection,
            :interest_accrued => interest_accured, :disbursed_amount => disbursed_amount, :outstanding_principal => outstanding_principal
          }
        end
      end
    end
    data
  end

  def check_holiday_on_date(date)
    week_day = date.strftime('%A')
    return ['Saturday', 'Sunday'].include?(week_day)
  end
end
