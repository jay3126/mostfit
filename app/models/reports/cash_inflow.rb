class CashInflow < Report

  attr_accessor :from_date, :to_date

  def initialize(params, dates, user)
    @from_date = (dates and dates[:from_date]) ? dates[:from_date] : Date.today - 7
    @to_date   = (dates and dates[:to_date]) ? dates[:to_date] : Date.today
    @name = "Cash Inflow from #{@from_date} to #{@to_date}"
    @user = user
    get_parameters(params, user)
  end

  def name
    "Cash Inflow from #{@from_date} to #{@to_date}"
  end

  def self.name
    "Cash Inflow Report"
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

    schedule_dates = BaseScheduleLineItem.all(:on_date.gte => @from_date, :on_date.lte => @to_date).aggregate(:on_date) rescue []
    actual_dates = BaseScheduleLineItem.all(:on_date.gte => @from_date, :on_date.lte => @to_date).aggregate(:actual_date) rescue []
    data[:scheduled] = {}
    data[:actual_scheduled] = {}
    data[:from_date] = @from_date
    data[:to_date] = @to_date
    schedule_dates.each do |schedule_date|
      schedules = BaseScheduleLineItem.all(:on_date => schedule_date).aggregate(:scheduled_principal_due.sum, :scheduled_interest_due.sum) rescue []
      schedule_principal_amt = schedules.blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance_least_terms(schedules[0].to_i)
      schedule_interest_amt = schedules.blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance_least_terms(schedules[1].to_i)

      schedule_total_amt = schedule_principal_amt + schedule_interest_amt
      data[:scheduled][schedule_date] = {:schedule_date => schedule_date, :scheduled_total_amt => schedule_total_amt}
    end

    actual_dates.each do |actual_date|
      actual_schedules = BaseScheduleLineItem.all(:on_date => actual_date).aggregate(:scheduled_principal_due.sum, :scheduled_interest_due.sum) rescue []
      actual_schedule_principal_amt = actual_schedules.blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance_least_terms(actual_schedules[0].to_i)
      actual_schedule_interest_amt = actual_schedules.blank? ? MoneyManager.default_zero_money : MoneyManager.get_money_instance_least_terms(actual_schedules[1].to_i)

      actual_schedule_total_amt = actual_schedule_principal_amt + actual_schedule_interest_amt
      data[:actual_scheduled][actual_date] = {:actual_schedule_date => actual_date, :actual_scheduled_total_amt => actual_schedule_total_amt}
    end
    data
  end
end
