class PeriodicLoanStatusReport < Report

  attr_accessor :from_date, :to_date, :funding_line_id, :page

  validates_with_method :funding_line_id, :funding_line_not_selected

  def initialize(params, dates, user)
    @from_date = (dates && dates[:from_date]) ? dates[:from_date] : Date.today - 7
    @to_date   = (dates && dates[:to_date]) ? dates[:to_date] : Date.today
    @name = "Periodic Loan Status Report from #{@from_date} to #{@to_date}"
    @user = user
    all_funding_line_ids = NewFundingLine.all.map{|fl| fl.id}
    @funding_line_id = (params && params[:funding_line_id] && (not (params[:funding_line_id].empty?))) ? params[:funding_line_id] : all_funding_line_ids
    @page = params.blank? || params[:page].blank? ? 1 : params[:page]
    @limit = 10
    get_parameters(params, user)
  end

  def name
    "Periodic Loan Status Report from #{@from_date} to #{@to_date}"
  end

  def self.name
    "Periodic Loan Status Report"
  end

  def generate

    reporting_facade ||= FacadeFactory.instance.get_instance(FacadeFactory::REPORTING_FACADE, @user)
    data = {}

    loan_ids = FundingLineAddition.all(:funding_line_id => @funding_line_id).aggregate(:lending_id)
    loan_ids_with_disbursal_dates = Lending.all(:id => loan_ids, 'loan_base_schedule.base_schedule_line_items.on_date'.to_sym.gte => @from_date, 'loan_base_schedule.base_schedule_line_items.on_date'.to_sym.lte => @to_date).to_a.paginate(:page => @page, :per_page => @limit)
    data[:loan_ids] = loan_ids_with_disbursal_dates
    data[:loans] = {}
    zero_amount = MoneyManager.default_zero_money

    if !loan_ids_with_disbursal_dates.blank?
      loan_ids_with_disbursal_dates.each do |loan|
        loan_id = loan ? loan.id : "Not Specified"
        loan_lan = loan.lan
        loan_amount = (loan && loan.applied_amount) ? MoneyManager.get_money_instance(Money.new(loan.applied_amount.to_i, :INR).to_s) : Money.default_money_amount(:INR)
        disbursed_interest = loan.loan_base_schedule.to_money[:total_interest_applicable]
        loan_status = loan.status.to_s.humanize
        loan_disbursal_date = (loan && loan.disbursal_date) ? loan.disbursal_date : "Not Specified"
        loan_closure_date = (loan && loan.last_scheduled_date) ? loan.last_scheduled_date : "Not Specified"
        client = loan.loan_borrower.counterparty
        client_id = client ? client.id : "Not Specified"
        client_name = client ? client.name : "Not Specified"
        branch = BizLocation.get(loan.accounted_at_origin)
        branch_name = branch ? branch.name : "Not SPecified"
        location = LocationLink.all_parents(branch, @to_date)
        district = location.select{|s| s.location_level.name.downcase == 'district'}.first
        district_name = (district && (not district.blank?)) ? district.name : "Not Specified"
        installments_remaining = reporting_facade.number_of_installments_per_loan(loan.id)
        no_of_installments_remaining = installments_remaining[:installments_remaining]
        loan_base_schedules = BaseScheduleLineItem.all('loan_base_schedule.lending_id' => loan.id)
        loan_receipts = loan.loan_receipts(:is_advance_adjusted => false)

        loan_base_schedules_till_from_date = loan_base_schedules.blank? ? [] : loan_base_schedules.select{|s| s.on_date <= @from_date}
        loan_receipts_till_from_date = loan_receipts.blank? ? [] : loan_receipts.select{|s| s.effective_on <= @from_date}
        principal_schedule_till_from_date = loan_base_schedules_till_from_date.blank? ? zero_amount : MoneyManager.get_money_instance_least_terms(loan_base_schedules_till_from_date.map(&:scheduled_principal_due).sum.to_i)
        interest_schedule_till_from_date = loan_base_schedules_till_from_date.blank? ? zero_amount : MoneyManager.get_money_instance_least_terms(loan_base_schedules_till_from_date.map(&:scheduled_interest_due).sum.to_i)
        principal_outstanding_from_date = loan_amount > principal_schedule_till_from_date ?  loan_amount - principal_schedule_till_from_date : zero_amount
        interest_outstanding_from_date = disbursed_interest > interest_schedule_till_from_date ?  disbursed_interest - interest_schedule_till_from_date : zero_amount
        principal_received_from_date = loan_receipts_till_from_date.blank? ? zero_amount : MoneyManager.get_money_instance_least_terms(loan_receipts_till_from_date.map(&:principal_received).sum.to_i)
        interest_received_from_date = loan_receipts_till_from_date.blank? ? zero_amount : MoneyManager.get_money_instance_least_terms(loan_receipts_till_from_date.map(&:interest_received).sum.to_i)
        
        loan_base_schedules_till_to_date = loan_base_schedules.blank? ? [] : loan_base_schedules.select{|s| s.on_date <= @to_date}
        loan_receipts_till_to_date = loan_receipts.blank? ? [] : loan_receipts.select{|s| s.effective_on <= @to_date}
        principal_schedule_till_to_date = loan_base_schedules_till_to_date.blank? ? zero_amount : MoneyManager.get_money_instance_least_terms(loan_base_schedules_till_to_date.map(&:scheduled_principal_due).sum.to_i)
        interest_schedule_till_to_date = loan_base_schedules_till_to_date.blank? ? zero_amount : MoneyManager.get_money_instance_least_terms(loan_base_schedules_till_to_date.map(&:scheduled_interest_due).sum.to_i)
        principal_outstanding_to_date = loan_amount > principal_schedule_till_to_date ?  loan_amount - principal_schedule_till_to_date : zero_amount
        interest_outstanding_to_date = disbursed_interest > interest_schedule_till_to_date ?  disbursed_interest - interest_schedule_till_to_date : zero_amount
        principal_received_to_date = loan_receipts_till_to_date.blank? ? zero_amount : MoneyManager.get_money_instance_least_terms(loan_receipts_till_to_date.map(&:principal_received).sum.to_i)
        interest_received_to_date = loan_receipts_till_to_date.blank? ? zero_amount : MoneyManager.get_money_instance_least_terms(loan_receipts_till_to_date.map(&:interest_received).sum.to_i)


        principal_due_during_week = principal_schedule_till_to_date > principal_schedule_till_from_date ? principal_schedule_till_to_date - principal_schedule_till_from_date : zero_amount
        interest_due_during_week = interest_schedule_till_to_date > interest_schedule_till_from_date ? interest_schedule_till_to_date - interest_schedule_till_from_date : zero_amount
        
        loan_receipts_during_week = loan_receipts.select{|s| s.effective_on >= @to_date && s.effective_on <= @from_date}
        principal_paid_during_week = loan_receipts_during_week.blank? ? zero_amount : MoneyManager.get_money_instance_least_terms(loan_receipts_during_week.map(&:principal_received).sum.to_i)
        interest_paid_during_week = loan_receipts_during_week.blank? ? zero_amount : MoneyManager.get_money_instance_least_terms(loan_receipts_during_week.map(&:interest_received).sum.to_i)


        principal_overdue = principal_schedule_till_to_date > principal_received_to_date ? principal_schedule_till_to_date - principal_received_to_date : zero_amount
        interest_overdue = interest_schedule_till_to_date > interest_received_to_date ? interest_schedule_till_to_date - interest_received_to_date : zero_amount

        schedule_till_current_date = loan_base_schedules.blank? ? [] : loan_base_schedules.select{|s| s.on_date <= Date.today}
        principal_schedule_till_current_date = schedule_till_current_date.blank? ? [] : MoneyManager.get_money_instance_least_terms(schedule_till_current_date.map(&:scheduled_principal_due).sum.to_i)
        interest_schedule_till_current_date = schedule_till_current_date.blank? ? [] : MoneyManager.get_money_instance_least_terms(schedule_till_current_date.map(&:scheduled_interest_due).sum.to_i)
        
        current_principal_outstanding = loan_amount > principal_schedule_till_current_date ? loan_amount - principal_schedule_till_current_date : zero_amount
        current_interest_outstanding = disbursed_interest > interest_schedule_till_current_date ? disbursed_interest - interest_schedule_till_current_date : zero_amount
        number_of_days_overdue = loan.days_past_dues_on_date(@from_date)


        data[:loans][loan] = {:client_id => client_id, :client_name => client_name, :loan_id => loan_id, :loan_lan => loan_lan, :district_name => district_name,
          :branch_name => branch_name, :no_of_installments_remaining => no_of_installments_remaining,
          :principal_outstanding_beginning_of_week => principal_outstanding_from_date,
          :principal_due_during_week => principal_due_during_week, :principal_paid_during_week => principal_paid_during_week,
          :principal_overdue => principal_overdue, :number_of_days_principal_overdue => number_of_days_overdue,
          :current_principal_outstanding => current_principal_outstanding,
          :interest_outstanding_beginning_of_week => interest_outstanding_from_date, :interest_due_during_week => interest_due_during_week,
          :interest_paid_during_week => interest_paid_during_week, :interest_overdue => interest_overdue,
          :number_of_days_interest_overdue => number_of_days_overdue, :current_interest_outstanding => current_interest_outstanding,
          :loan_amount => loan_amount, :loan_disbursal_date => loan_disbursal_date, :loan_status => loan_status,
          :loan_closure_date => loan_closure_date}
      end
      data
    end
  end

  def funding_line_not_selected
    return [false, "Please select Funding Line"] if self.respond_to?(:funding_line_id) && !self.funding_line_id
    return true
  end
end