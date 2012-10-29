class SecuritizationLoanStatus < Report
  attr_accessor :from_date, :to_date

  def initialize(params, dates, user)
    @from_date = (dates and dates[:from_date]) ? dates[:from_date] : Date.today - 7
    @to_date   = (dates and dates[:to_date]) ? dates[:to_date] : Date.today
    @name   = "Report from #{@from_date} to #{@to_date}"
    get_parameters(params, user)
  end

  def name
    "Securitization Loan Status #{@from_date} to #{@to_date}"
  end

  def self.name
    "Securitization Loan Status"
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
    data = {}
    loan_assignment_facade = LoanAssignmentFacade.new(User.first)
    loan_ids = loan_assignment_facade.get_loans_assigned_in_date_range(Constants::LoanAssignment::SECURITISED, @from_date, @to_date)

    if !loan_ids.blank?
      loan_ids.each do |l|
        loan = Lending.get(l)
        loan_id = loan.id
        client = loan.borrower
        client_id = client ? client.id : "Not Specified"
        client_name = client ? client.name : "Not Specified"
        branch = BizLocation.get(loan.accounted_at_origin)
        branch_name = branch ? branch.name : "Not Specified"
        location = LocationLink.all_parents(branch, @to_date)
        district = location.select{|s| s.location_level.name.downcase == 'district'}.first
        district_name = (district and (not district.blank?)) ? district.name : "Not Specified"
        loan_amount = loan.to_money[:applied_amount]
        loan_disbursal_date = (loan and loan.disbursal_date) ? loan.disbursal_date : "Not Specified"
        loan_status = loan.status.humanize
        loan_closure_date = loan.last_scheduled_date
        installments_remaining = reporting_facade.number_of_installments_per_loan(loan.id)
        no_of_installments_remaining = installments_remaining[:installments_remaining]
        principal_outstanding_begining_of_period = loan.scheduled_principal_outstanding(@from_date)

        if loan.scheduled_principal_due(@to_date) > loan.scheduled_principal_due(@from_date)
          principal_due_during_period = loan.scheduled_principal_due(@to_date) - loan.scheduled_principal_due(@from_date)
        else
          principal_due_during_period = loan.scheduled_principal_due(@from_date) - loan.scheduled_principal_due(@to_date)
        end

        if loan.principal_received_till_date(@from_date) > loan.principal_received_till_date(@to_date)
          principal_paid_during_period = loan.principal_received_till_date(@from_date) - loan.principal_received_till_date(@to_date)
        else
          principal_paid_during_period = loan.principal_received_till_date(@to_date) - loan.principal_received_till_date(@from_date)
        end

        if loan.scheduled_principal_outstanding(@to_date) > loan.actual_principal_outstanding(@to_date)
          principal_overdue = loan.scheduled_principal_outstanding(@to_date) - loan.actual_principal_outstanding(@to_date)
        else
          principal_overdue = loan.actual_principal_outstanding(@to_date) - loan.scheduled_principal_outstanding(@to_date)
        end

        number_of_days_principal_overdue = loan.days_past_dues_on_date(@from_date)
        current_principal_outstanding = loan.actual_principal_outstanding(@to_date)
        interest_outstanding_begining_of_period = loan.scheduled_interest_outstanding(@from_date)

        if loan.scheduled_interest_due(@from_date) > loan.scheduled_interest_due(@to_date)
          interest_due_during_period = loan.scheduled_interest_due(@from_date) - loan.scheduled_interest_due(@to_date)
        else
          interest_due_during_period = loan.scheduled_interest_due(@to_date) - loan.scheduled_interest_due(@from_date)
        end

        if loan.interest_received_till_date(@from_date) > loan.interest_received_till_date(@to_date)
          interest_paid_during_period = loan.interest_received_till_date(@from_date) - loan.interest_received_till_date(@to_date)
        else
          interest_paid_during_period = loan.interest_received_till_date(@to_date) - loan.interest_received_till_date(@from_date)
        end

        if loan.scheduled_interest_outstanding(@to_date) > loan.actual_interest_outstanding(@to_date)
          interest_overdue = loan.scheduled_interest_outstanding(@to_date) - loan.actual_interest_outstanding(@to_date)
        else
          interest_overdue = loan.actual_interest_outstanding(@to_date) - loan.scheduled_interest_outstanding(@to_date)
        end

        number_of_days_interest_outstanding = loan.days_past_dues_on_date(@from_date)
        current_interest_outstanding = loan.actual_interest_outstanding(@to_date)

        data[loan] = {:client_id => client_id, :client_name => client_name, :loan_id => loan_id, :district_name => district_name,
          :branch_name => branch_name, :no_of_installments_remaining => no_of_installments_remaining,
          :principal_outstanding_beginning_of_week => principal_outstanding_beginning_of_week,
          :principal_due_during_week => principal_due_during_week, :principal_paid_during_week => principal_paid_during_week,
          :principal_overdue => principal_overdue, :number_of_days_principal_overdue => number_of_days_principal_overdue,
          :current_principal_outstanding => current_principal_outstanding,
          :interest_outstanding_beginning_of_week => interest_outstanding_beginning_of_week, :interest_due_during_week => interest_due_during_week,
          :interest_paid_during_week => interest_paid_during_week, :interest_overdue => interest_overdue,
          :number_of_days_interest_overdue => number_of_days_interest_overdue, :current_interest_outstanding => current_interest_outstanding,
          :loan_amount => loan_amount, :loan_disbursal_date => loan_disbursal_date, :loan_status => loan_status,
          :loan_closure_date => loan_closure_date}
      end
      data
    end
  end
end
