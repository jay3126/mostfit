class NewDailyReport < Report
  attr_accessor :date, :branch_id   #, :loan_product_id, :staff_member_id, :center_id

  def initialize(params, dates, user)
    @date = dates[:date] || Date.today
    @name = "Daily Report for #{@date}"
    get_parameters(params, user)
  end

  def name
    "Daily Report for #{@date}"
  end

  def self.name
    "Daily Report"
  end

  def generate

    data = {}
=begin
    The report will be filtered with branch as of now.
    daily report will have following columns :-
    1. loan amounts (applied, approved and disbursed)
    2. Repayment amounts (Principal, Interest, Total, Fees)
    3. Balance Outstandings (Principal, Interest, Total)
    4. Balance Overdue (Principal, Interest, Total)
    5. Advance Payments (Collected, Adjusted, Balance)
=end
  end
end
