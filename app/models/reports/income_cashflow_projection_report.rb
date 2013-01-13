class IncomeCashflowProjectionReport < Report

  attr_accessor :from_date, :to_date, :page

  def initialize(params, dates, user)
    @from_date = (dates and dates[:from_date]) ? dates[:from_date] : Date.today - 30
    @to_date   = (dates and dates[:to_date]) ? dates[:to_date] : Date.today
    @name = "Income Cashflow Projection Report from #{@from_date} to #{@to_date}"
    @user = user
    @page = params.blank? || params[:page].blank? ? 1 : params[:page]
    @limit = 10
    get_parameters(params, user)
  end

  def name
    "Income Cashflow Projection Report from #{@from_date} to #{@to_date}"
  end

  def self.name
    "Income Cashflow Projection Report"
  end

  def default_currency
    @default_currency = MoneyManager.get_default_currency
  end

  def generate
    data = {}

    data[:loan] = {}

    date = @from_date
    disbursed_loans = repository.adapter.query("select id, disbursed_amount from lendings where status = 5 and disbursal_date <= '#{@to_date.strftime('%Y-%m-%d')}'")
    disbursed_loan_ids = disbursed_loans.blank? ? [] : disbursed_loans.map(&:id)
    loan_base_schedules = disbursed_loans.blank? ? [] : LoanBaseSchedule.all(:lending_id => disbursed_loan_ids).aggregate(:id)
    max_schedule_date = loan_base_schedules.blank? ? [] : BaseScheduleLineItem.all(:loan_base_schedule_id => loan_base_schedules).aggregate(:on_date.max)
    (0..(@to_date.year * 12 + @to_date.month) - (@from_date.year * 12 + @from_date.month)).each do |x|

      f_date = date.first_day_of_month
      l_date = date.last_day_of_month

      first_date = f_date <= @from_date ? @from_date : f_date
      last_date = l_date >= @to_date ? @to_date : l_date
      data[:loan][first_date] = {}
      
      schedule_till_last_date = disbursed_loan_ids.blank? ? [] : BaseScheduleLineItem.all(:loan_base_schedule_id => loan_base_schedules, :on_date.lte => last_date).aggregate(:scheduled_principal_due.sum) rescue []
      schedule_infos = disbursed_loan_ids.blank? || first_date > max_schedule_date ? [] : BaseScheduleLineItem.all(:loan_base_schedule_id => loan_base_schedules, :on_date.lte => last_date, :on_date.gte => first_date).aggregate(:scheduled_principal_due.sum, :scheduled_interest_due.sum) rescue []

      disbursed_loan_amount = disbursed_loan_ids.blank? ? []  : disbursed_loans.map(&:disbursed_amount).sum
      disbursed_amount = disbursed_loan_amount.blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance_least_terms(disbursed_loan_amount.to_i)

      schedule_principal_till_last_date = schedule_till_last_date.blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance_least_terms(schedule_till_last_date.to_i)
      schedule_principal_realisations = schedule_infos.blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance_least_terms(schedule_infos[0].to_i)
      schedule_interest_realisations = schedule_infos.blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance_least_terms(schedule_infos[1].to_i)
      schedule_total_realisations = schedule_principal_realisations + schedule_interest_realisations

      projected_interest_accrual = schedule_interest_realisations
      projected_pos_at_monthend = disbursed_amount > schedule_principal_till_last_date ? disbursed_amount - schedule_principal_till_last_date : MoneyManager.default_zero_money


      data[:loan][first_date] = {:from_date => first_date, :to_date => last_date, :projected_pos_at_monthend => projected_pos_at_monthend, :schedule_principal_realisations => schedule_principal_realisations, :schedule_interest_realisations => schedule_interest_realisations, :schedule_total_realisations => schedule_total_realisations, :projected_interest_accrual => projected_interest_accrual}
      date = last_date + 1
    end
    data
  end
end