class NewDailyReport < Report
  attr_accessor :date, :biz_location_branch

  def initialize(params, dates, user)
    @date = dates[:date] || Date.today
    @name = "Daily Report for #{@date}"
    get_parameters(params, user)
  end

  def name
    "New Daily Report for #{@date}"
  end

  def self.name
    "New Daily Report"
  end

  def generate

    data = {}

    #loan amounts (applied, approved and disbursed)
    loan_applied_amount = Lending.all(:applied_on_date => @date).aggregate(:applied_amount.sum)
    loan_approved_amount = Lending.all(:approved_on_date => @date).aggregate(:approved_amount.sum)
    loan_disbursed_amount = Lending.all(:disbursal_date => @date).aggregate(:disbursed_amount.sum)

    
=begin
    The report will be filtered with branch as of now.
    daily report will have following columns :-
    2. Repayment amounts (Principal, Interest, Total, Fees)
    3. Balance Outstandings (Principal, Interest, Total)
    4. Balance Overdue (Principal, Interest, Total)
    5. Advance Payments (Collected, Adjusted, Balance)
=end
  end
end
