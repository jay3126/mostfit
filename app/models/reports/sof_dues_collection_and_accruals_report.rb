class SOFDuesCollectionAndAccrualsReport < Report

  attr_accessor :from_date, :to_date, :funding_line_id

  validates_with_method :funding_line_id, :funding_line_not_selected

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

    loan_ids = FundingLineAddition.all(:funding_line_id => @funding_line_id).aggregate(:lending_id)
    loan_ids.each do |l|
      loan = Lending.get(l)
      branch = BizLocation.get(loan.accounted_at_origin)
      branch_name = branch ? branch.name : "Not Specified"
      branch_id = branch ? branch.id : "Not Specified"
      
      if loan.scheduled_principal_due(@to_date) > loan.scheduled_principal_due(@from_date)
        ewi_principal_due = loan.scheduled_principal_due(@to_date) - loan.scheduled_principal_due(@from_date)
      else
        ewi_principal_due = loan.scheduled_principal_due(@from_date) - loan.scheduled_principal_due(@to_date)
      end

      if loan.scheduled_interest_due(@from_date) > loan.scheduled_interest_due(@to_date)
        ewi_interest_due = loan.scheduled_interest_due(@from_date) - loan.scheduled_interest_due(@to_date)
      else
        ewi_interest_due = loan.scheduled_interest_due(@to_date) - loan.scheduled_interest_due(@from_date)
      end
      ewi_total_due = ewi_principal_due + ewi_interest_due

      if loan.principal_received_till_date(@from_date) > loan.principal_received_till_date(@to_date)
        ewi_principal_paid = loan.principal_received_till_date(@from_date) - loan.principal_received_till_date(@to_date)
      else
        ewi_principal_paid = loan.principal_received_till_date(@to_date) - loan.principal_received_till_date(@from_date)
      end

      if loan.interest_received_till_date(@from_date) > loan.interest_received_till_date(@to_date)
        ewi_interest_paid = loan.interest_received_till_date(@from_date) - loan.interest_received_till_date(@to_date)
      else
        ewi_interest_paid = loan.interest_received_till_date(@to_date) - loan.interest_received_till_date(@from_date)
      end

      ewi_total_paid = ewi_principal_paid + ewi_interest_paid
      outstanding_principal = loan.actual_principal_outstanding(@to_date)
      disbursed_amount = (loan and loan.disbursed_amount) ? MoneyManager.get_money_instance(Money.new(loan.disbursed_amount.to_i, :INR).to_s) : Money.default_money_amount(:INR)
      interest_accrued = loan.accrued_interim_interest(@from_date, @to_date)

      data[loan] = {:branch_id => branch_id, :branch_name => branch_name, :ewi_principal_due => ewi_principal_due, :ewi_interest_due => ewi_interest_due, :ewi_total_due => ewi_total_due, :ewi_principal_paid => ewi_principal_paid, :ewi_interest_paid => ewi_interest_paid, :ewi_total_paid => ewi_total_paid, :outstanding_principal => outstanding_principal, :disbursed_amount => disbursed_amount, :interest_accrued => interest_accrued}
    end
    data
=begin
Columns required in this report are as follows:
   d. Processiing Fees
   e. Foreclosure Fees
   f. Foreclosure POS
   g. Total Collected
=end
  end

  def funding_line_not_selected
    return [false, "Please select Funding Line"] if self.respond_to?(:funding_line_id) and not self.funding_line_id
    return true
  end
end
