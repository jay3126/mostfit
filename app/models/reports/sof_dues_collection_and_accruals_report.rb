#SOF is Source of Fund which means Funding Lines.

class SOFDuesCollectionAndAccrualsReport < Report

  attr_accessor :from_date, :to_date

  def initialize(params, dates, user)
    @from_date = (dates and dates[:from_date]) ? dates[:from_date] : Date.today - 30
    @to_date   = (dates and dates[:to_date]) ? dates[:to_date] : Date.today
    @name = "SOF Dues Collection and Accrual Report from #{@from_date} to #{@to_date}"
    @user = user
    get_parameters(params, user)
  end

  def name
    "SOF Dues Collection and Accrual Report from #{@from_date} to #{@to_date}"
  end

  def self.name
    "SOF Dues Collection and Accrual Report"
  end

  def get_reporting_facade(user)
    @reporting_facade ||= FacadeFactory.instance.get_instance(FacadeFactory::REPORTING_FACADE, user)
  end

  def default_currency
    @default_currency = MoneyManager.get_default_currency
  end

  def generate

    reporting_facade = get_reporting_facade(@user)
    data = {}

=begin
Columns required in this report are as follows:
1. Dues
   a. EWI due principal
   b. EWI due interest
   c. EWI due total
2. Collections
   a. EWI Collected Principal
   b. EWI Collected Interest
   c. EWI Collected Total
   d. Processiing Fees
   e. Foreclosure Fees
   f. Foreclosure POS
   g. Total Collected
3. Disbursal, Accrual, POS
   a. Interest Accrued
   b. Disbursed Amount
   c. Outstanding Principal
=end
  end
end
