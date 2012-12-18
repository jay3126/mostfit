class LoanStatusReport < Report

  attr_accessor :from_date, :to_date, :funding_line_id, :page

  validates_with_method :funding_line_id, :funding_line_not_selected

  def initialize(params, dates, user)
    @from_date = (dates && dates[:from_date]) ? dates[:from_date] : Date.today - 7
    @to_date   = (dates && dates[:to_date]) ? dates[:to_date] : Date.today
    @name = "Loan Status Report from #{@from_date} to #{@to_date}"
    @user = user
    @page = params.blank? || params[:page].blank? ? 1 : params[:page]
    @limit = 10
    get_parameters(params, user)
  end

  def name
    "Loan Status Report from #{@from_date} to #{@to_date}"
  end

  def self.name
    "Loan Status Report"
  end

  def get_location_facade(user)
    @location_facade ||= FacadeFactory.instance.get_instance(FacadeFactory::LOCATION_FACADE, user)
  end

  def default_currency
    @default_currency = MoneyManager.get_default_currency
  end

  def generate

    reporting_facade ||= FacadeFactory.instance.get_instance(FacadeFactory::REPORTING_FACADE, @user)
    data = {}

    loan_ids = FundingLineAddition.all(:funding_line_id => @funding_line_id).aggregate(:lending_id)
    loan_ids_with_disbursal_dates = Lending.all(:id => loan_ids, :disbursal_date.gte => @from_date, :disbursal_date.lte => @to_date).to_a.paginate(:page => @page, :per_page => @limit)
    data[:loan_ids] = loan_ids_with_disbursal_dates
    data[:loans] = {}

    loan_ids_with_disbursal_dates.each do |loan|
      client = loan.loan_borrower.counterparty
      client_id = client ? client.id : "Not Specified"
      client_name = client ? client.name : "Not Specified"
      loan_id = loan ? loan.id : "Not Specified"
      loan_lan = (loan && loan.lan) ? loan.lan : "Not Specified"
      branch = BizLocation.get(loan.accounted_at_origin)
      branch_name = branch ? branch.name : "Not Specified"
      branch_id = branch ? branch.id : "Not Specified"
      location = LocationLink.all_parents(branch, @to_date)
      district = location.select{|s| s.location_level.name.downcase == 'district'}.first
      district_name = (district && (!district.blank?)) ? district.name : "Not Specified"
      district_id = (district && (!district.blank?)) ? district.id : "Not Specified"
      no_of_installments_remaining = reporting_facade.number_of_installments_per_loan(loan.id)
      principal_outstanding_beginning_of_week = loan.scheduled_principal_outstanding(@from_date)

      if loan.scheduled_principal_due(@to_date) > loan.scheduled_principal_due(@from_date)
        principal_due_during_week = loan.scheduled_principal_due(@to_date) - loan.scheduled_principal_due(@from_date)
      else
        principal_due_during_week = loan.scheduled_principal_due(@from_date) - loan.scheduled_principal_due(@to_date)
      end

      if loan.principal_received_till_date(@from_date) > loan.principal_received_till_date(@to_date)
        principal_paid_during_week = loan.principal_received_till_date(@from_date) - loan.principal_received_till_date(@to_date)
      else
        principal_paid_during_week = loan.principal_received_till_date(@to_date) - loan.principal_received_till_date(@from_date)
      end

      if loan.scheduled_principal_outstanding(@to_date) > loan.actual_principal_outstanding(@to_date)
        principal_overdue = loan.scheduled_principal_outstanding(@to_date) - loan.actual_principal_outstanding(@to_date)
      else
        principal_overdue = loan.actual_principal_outstanding(@to_date) - loan.scheduled_principal_outstanding(@to_date)
      end

      current_principal_outstanding = loan.actual_principal_outstanding
      interest_outstanding_beginning_of_week = loan.scheduled_interest_outstanding(@from_date)

      if loan.scheduled_interest_due(@from_date) > loan.scheduled_interest_due(@to_date)
        interest_due_during_week = loan.scheduled_interest_due(@from_date) - loan.scheduled_interest_due(@to_date)
      else
        interest_due_during_week = loan.scheduled_interest_due(@to_date) - loan.scheduled_interest_due(@from_date)
      end

      if loan.interest_received_till_date(@from_date) > loan.interest_received_till_date(@to_date)
        interest_paid_during_week = loan.interest_received_till_date(@from_date) - loan.interest_received_till_date(@to_date)
      else
        interest_paid_during_week = loan.interest_received_till_date(@to_date) - loan.interest_received_till_date(@from_date)
      end

      if loan.scheduled_interest_outstanding(@to_date) > loan.actual_interest_outstanding(@to_date)
        interest_overdue = loan.scheduled_interest_outstanding(@to_date) - loan.actual_interest_outstanding(@to_date)
      else
        interest_overdue = loan.actual_interest_outstanding(@to_date) - loan.scheduled_interest_outstanding(@to_date)
      end

      number_of_days_overdue = loan.days_past_dues_on_date(@from_date)
      current_interest_outstanding = loan.actual_interest_outstanding

      data[:loans][loan] = {:client_id => client_id, :client_name => client_name, :loan_id => loan_id, :district_id => district_id, :district_name => district_name, :branch_id => branch_id, :branch_name => branch_name, :no_of_installments_remaining => no_of_installments_remaining, :principal_outstanding_beginning_of_week => principal_outstanding_beginning_of_week, :principal_due_during_week => principal_due_during_week, :principal_paid_during_week => principal_paid_during_week, :principal_overdue => principal_overdue, :number_of_days_principal_overdue => number_of_days_overdue, :current_principal_outstanding => current_principal_outstanding, :interest_outstanding_beginning_of_week => interest_outstanding_beginning_of_week, :interest_due_during_week => interest_due_during_week, :interest_paid_during_week => interest_paid_during_week, :interest_overdue => interest_overdue, :number_of_days_interest_overdue => number_of_days_overdue, :current_interest_outstanding => current_interest_outstanding, :loan_lan => loan_lan}
    end
    data
  end

  def funding_line_not_selected
    return [false, "Please select Funding Line"] if self.respond_to?(:funding_line_id) && !self.funding_line_id
    return true
  end
end