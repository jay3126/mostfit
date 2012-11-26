class DailyRepaymentDetailReport < Report
  attr_accessor :date

  def initialize(params, date, user)
    @date = date.blank? ? Date.today : date[:date]
    @name = "Report on #{@date}"
    get_parameters(params, user)
  end

  def name
    "Daily Repayment Detail Report on #{@date}"
  end

  def self.name
    "Daily Repayment Report"
  end

  def generate
    BaseScheduleLineItem.all(:on_date => @date, 'loan_base_schedule.lending.status' => LoanLifeCycle::DISBURSED_LOAN_STATUS, 'loan_base_schedule.lending.disbursal_date.lte' => @date)
  end

end