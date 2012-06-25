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
    daily_reports = {}
    loans       = Lending.all(:status => LoanLifeCycle::DISBURSED_LOAN_STATUS)
    loan_facade = FacadeFactory.instance.get_instance(FacadeFactory::LOAN_FACADE, @user)
    loans.each do |loan|
      schedule_item = loan_facade.previous_and_current_amortization_items(loan.id, @date)
      
      if schedule_item.size == 1
        schedule_total_due = schedule_item.first.last[:scheduled_principal_due] + schedule_item.first.last[:scheduled_interest_due]
        daily_reports[loan.id] = {:loan_id => loan.id, :lan => loan.lan, :accounted_at => loan.accounted_at_origin_location.name, :administered_at => loan.administered_at_origin_location.name, :schedule_date => schedule_item.first.first.last, :schedule_principal_due => schedule_item.first.last[:scheduled_principal_due], :schedule_interest_due => schedule_item.first.last[:scheduled_interest_due], :total_due => schedule_total_due}
      end
    end
    daily_reports
  end

end