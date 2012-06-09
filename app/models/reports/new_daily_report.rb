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

    #finding out a list of loan_ids at a particular biz_location and on a particular date
    loan_facade = FacadeFactory.instance.get_instance(FacadeFactory::LOAN_FACADE, @user)
    loan_ids = loan_facade.get_loans_at_location(@biz_location_branch, @date)

    #loan amounts (applied, approved and disbursed)
    loan_applied_amount = Lending.all(:id => loan_ids, :applied_on_date => @date).aggregate(:applied_amount.sum)
    loan_approved_amount = Lending.all(:id => loan_ids, :approved_on_date => @date).aggregate(:approved_amount.sum)
    loan_disbursed_amount = Lending.all(:id => loan_ids, :disbursal_date => @date).aggregate(:disbursed_amount.sum)

    
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
