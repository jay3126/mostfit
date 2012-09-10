class OngoingLoanInformationReport < Report

  attr_accessor :from_date, :to_date, :biz_location_branch

  def initialize(params, dates, user)
    @from_date = (dates and dates[:from_date]) ? dates[:from_date] : Date.today - 7
    @to_date   = (dates and dates[:to_date]) ? dates[:to_date] : Date.today
    @name = "Ongoing Loan Information Report from #{@from_date} to #{@to_date}"
    @user = user
    location_facade = get_location_facade(@user)
    all_branch_ids = location_facade.all_nominal_branches.collect {|branch| branch.id}
    @biz_location_branch = (params and params[:biz_location_branch] and (not (params[:biz_location_branch].empty?))) ? params[:biz_location_branch] : all_branch_ids
    get_parameters(params, user)
  end

  def name
    "Ongoing Loan Information Report from #{@from_date} to #{@to_date}"
  end

  def self.name
    "Ongoing Loan Information Report"
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

    params = {:accounted_at_origin => @biz_location_branch, :status => :disbursed_loan_status}
    lending_ids = Lending.all(params).aggregate(:id)
    lending_ids.each do |l|

      loan = Lending.get(l)
      client = loan.loan_borrower.counterparty
      client_id = client ? client.id : "Not Specified"
      client_name = client ? client.name : "Not Specified"
      loan_id = loan ? loan.id : "Not Specified"
      loan_lan = (loan and loan.lan) ? loan.lan : "Not Specified"
      branch = BizLocation.get(loan.accounted_at_origin)
      branch_name = branch ? branch.name : "Not Specified"
      branch_id = branch ? branch.id : "Not Specified"
      area = location_facade.get_parent(branch, @date)
      district = location_facade.get_parent(area, @date)
      district_name = district ? district.name : "Not Specified"
      district_id = district ? district.id : "Not Specified"
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

      if loan.scheduled_principal_outstanding(@from_date) > loan.actual_principal_outstanding
        principal_overdue = loan.scheduled_principal_outstanding(@from_date) - loan.actual_principal_outstanding
      else
        principal_overdue = loan.actual_principal_outstanding - loan.scheduled_principal_outstanding(@from_date)
      end

      number_of_days_principal_overdue = loan.days_past_due_on_date(@from_date)
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

      if loan.scheduled_interest_outstanding(@from_date) > loan.actual_interest_outstanding
        interest_overdue = loan.scheduled_interest_outstanding(@from_date) - loan.actual_interest_outstanding
      else
        interest_overdue = loan.actual_interest_outstanding - loan.scheduled_interest_outstanding(@from_date)
      end

      number_of_days_interest_overdue = loan.days_past_due_on_date(@from_date)
      current_interest_outstanding = loan.actual_interest_outstanding

      data[loan] = {:client_id => client_id, :client_name => client_name, :loan_id => loan_id, :district_id => district_id, :district_name => district_name, :branch_id => branch_id, :branch_name => branch_name, :no_of_installments_remaining => no_of_installments_remaining, :principal_outstanding_beginning_of_week => principal_outstanding_beginning_of_week, :principal_due_during_week => principal_due_during_week, :principal_paid_during_week => principal_paid_during_week, :principal_overdue => principal_overdue, :number_of_days_principal_overdue => number_of_days_principal_overdue, :current_principal_outstanding => current_principal_outstanding, :interest_outstanding_beginning_of_week => interest_outstanding_beginning_of_week, :interest_due_during_week => interest_due_during_week, :interest_paid_during_week => interest_paid_during_week, :interest_overdue => interest_overdue, :number_of_days_interest_overdue => number_of_days_interest_overdue, :current_interest_outstanding => current_interest_outstanding, :loan_lan => loan_lan}
    end
    data
  end
end
