class SecuritizationLoanStatus < Report
  attr_accessor :securitization_id, :from_date, :to_date

  def initialize(params, dates, user)
    @from_date = (dates and dates[:from_date]) ? dates[:from_date] : Date.today - 7
    @to_date   = (dates and dates[:to_date]) ? dates[:to_date] : Date.today
    @name   = "Report from #{@from_date} to #{@to_date}"
    get_parameters(params, user)
  end

  def name
    "Securitization Loan Status #{from_date} to #{to_date}"
  end

  def self.name
    "Securitization Loan Status"
  end

  def generate
    securitization = Securitization.get(@securitization_id)
    loan_assignment_facade = LoanAssignmentFacade.new(User.first)
    loan_ids = loan_assignment_facade.get_loans_assigned(securitization)
    @data = loan_ids
  end

end
