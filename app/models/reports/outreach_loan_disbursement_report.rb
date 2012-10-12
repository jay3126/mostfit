class OutreachLoanDisbursementReport < Report

  attr_accessor :from_date, :to_date

  def initialize(params, dates, user)
    @from_date = (dates and dates[:from_date]) ? dates[:from_date] : Date.today - 30
    @to_date   = (dates and dates[:to_date]) ? dates[:to_date] : Date.today
    @name = "Outreach Loan Disbursement Report from #{@from_date} to #{@to_date}"
    @user = user
    get_parameters(params, user)
  end

  def name
    "Outreach Loan Disbursement Report from #{@from_date} to #{@to_date}"
  end

  def self.name
    "Outreach Loan Disbursement Report"
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
    data = {:loan_disbursement_by_caste => {}, :loan_disbursement_by_religion => {}}

    #loan_disbursement_by_caste
    caste_master_list = Constants::Masters::CASTE_CHOICE
    caste_master_list.each do |caste|
      caste_name = caste.to_s.humanize
      loans_disbursed_during_period_per_caste = Lending.all(:disbursal_date.gte => @from_date, :disbursal_date.lte => @to_date).select{|ld| ld.borrower_caste == caste}
      total_pos_per_caste = MoneyManager.default_zero_money
      disbursed_loan_count = loans_disbursed_during_period_per_caste.count
      loans_disbursed_during_period_per_caste.each do |loan|
        total_pos_per_caste += loan.actual_principal_outstanding(@to_date)
      end
      data[:loan_disbursement_by_caste][caste] = {:caste_name => caste_name, :total_pos => total_pos_per_caste, :disbursed_loan_count => disbursed_loan_count}
    end

    #loan_disbursement_by_religion
    religion_master_list = Constants::Masters::RELIGION_CHOICE
    religion_master_list.each do |religion|
      religion_name = religion.to_s.humanize
      total_pos_per_religion = MoneyManager.default_zero_money      
      loans_disbursed_during_period_per_religion = Lending.all(:disbursal_date.gte => @from_date, :disbursal_date.lte => @to_date).select{|ld| ld.borrower_religion == religion}
      disbursed_loan_count = loans_disbursed_during_period_per_religion.count
      loans_disbursed_during_period_per_religion.each do |loan|
        total_pos_per_religion += loan.actual_principal_outstanding(@to_date)
      end
      data[:loan_disbursement_by_religion][religion] = {:religion_name => religion_name, :total_pos => total_pos_per_religion, :disbursed_loan_count => disbursed_loan_count}
    end

    return data
  end
end
