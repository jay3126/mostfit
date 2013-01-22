class LoanExtractForSourceOfFundDetails < Report

  attr_accessor :from_date, :to_date, :funding_line_id, :page

  validates_with_method :funding_line_id, :funding_line_not_selected

  def initialize(params, dates, user)
    @from_date = (dates and dates[:from_date]) ? dates[:from_date] : Date.today - 7
    @to_date   = (dates and dates[:to_date]) ? dates[:to_date] : Date.today
    @name = "Loan Extract Source of Fund Details Report from #{@from_date} to #{@to_date}"
    @user = user
    @page = params.blank? || params[:page].blank? ? 1 : params[:page]
    @limit = 10
    get_parameters(params, user)
  end

  def name
    "Loan Extract Source of Fund Details Report from #{@from_date} to #{@to_date}"
  end

  def self.name
    "Loan Extract Source of Fund Details Report"
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

    loan_ids = FundingLineAddition.all(:funding_line_id => @funding_line_id).aggregate(:lending_id)
    loan_ids_with_disbursal_dates = Lending.all(:id => loan_ids, :disbursal_date.gte => @from_date, :disbursal_date.lte => @to_date).to_a.paginate(:page => @page, :per_page => @limit)
    data[:loan_ids] = loan_ids_with_disbursal_dates
    data[:loans] = {}

    loan_ids_with_disbursal_dates.each do |loan|
      loan_id = loan ? loan.id : "Not Specified"
      loan_lan_number = (loan and loan.lan) ? loan.lan : "Not Specified"
      loan_amount = (loan and loan.applied_amount) ? MoneyManager.get_money_instance(Money.new(loan.applied_amount.to_i, :INR).to_s) : Money.default_money_amount(:INR)
      loan_start_date = (loan and loan.loan_base_schedule) ? loan.loan_base_schedule.first_receipt_on : "Not Specified"
      loan_disbursal_date = (loan and loan.disbursal_date) ? loan.disbursal_date : "Not Specified"
      client = loan.loan_borrower.counterparty
      client_id = client ? client.client_identifier : "Not Specified"
      client_name = client ? client.name : "Not Specified"
      caste = (client and client.caste) ? client.caste.to_s.humanize : "Not Specified"
      religion = (client and client.religion) ? client.religion.to_s.humanize : "Not Specified"
      center = BizLocation.get(loan.administered_at_origin)
      center_name = center ? center.name : "Not Specified"
      funding_line = FundingLineAddition.all(:lending_id => loan.id).aggregate(:funding_line_id)
      source_of_fund = (funding_line and (not funding_line.nil?)) ? NewFundingLine.get(funding_line).name : "Not SPecified"
      pos = loan.scheduled_principal_outstanding(@to_date)
      overdue = reporting_facade.overdue_amounts(loan.id, @to_date)
      principal_overdue = overdue[:principal_overdue_amount]
      branch = BizLocation.get(loan.accounted_at_origin)
      branch_name = branch ? branch.name : "Not SPecified"
      location = LocationLink.all_parents(branch, @to_date)
      state = location.select{|s| s.location_level.name.downcase == 'state'}.first
      state_name = (state and (not state.blank?)) ? state.name : "Not Specified"
      district = location.select{|s| s.location_level.name.downcase == 'district'}.first
      district_name = (district and (not district.blank?)) ? district.name : "Not Specified"

      data[:loans][loan] = {:loan_id => loan_id, :loan_lan_number => loan_lan_number, :loan_amount => loan_amount, :loan_start_date => loan_start_date, :loan_disbursal_date => loan_disbursal_date, :client_id => client_id, :client_name => client_name, :caste => caste, :religion => religion, :center_name => center_name, :source_of_fund => source_of_fund, :pos => pos, :principal_overdue => principal_overdue, :branch_name => branch_name, :state_name => state_name, :district_name => district_name}
    end
    data
  end

  def funding_line_not_selected
    return [false, "Please select Funding Line"] if self.respond_to?(:funding_line_id) and not self.funding_line_id
    return true
  end
end
